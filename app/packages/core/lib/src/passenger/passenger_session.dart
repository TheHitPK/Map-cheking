import 'dart:async';

import '../eta/eta_estimator.dart';
import '../geo/geo.dart';
import '../geo/polyline.dart';
import '../mqtt/mqtt_link.dart';
import '../proto/api.pb.dart';
import '../proto/pos.pb.dart';
import '../protocol/protocol.dart';

/// What [PassengerSession] needs over HTTP; [ApiClient] implements it.
abstract interface class PassengerApi {
  Future<List<Nearby>> nearby(String line, GeoPoint user);
  Future<Route?> route(int veh, GeoPoint user);
}

/// What [PassengerSession] needs over MQTT; [MqttLink] implements it.
abstract interface class LiveFeed {
  Stream<MqttLinkMessage> get messages;
  Future<void> subscribe(String topic);
  void unsubscribe(String topic);
}

class VehicleView {
  const VehicleView({
    required this.veh,
    required this.at,
    required this.headingDeg,
    required this.speedKmh,
    required this.ts,
  });

  final int veh;
  final GeoPoint at;
  final double headingDeg;
  final double speedKmh;
  final int ts;
}

enum PassengerStatus { loading, tracking, noVehicles, error }

class PassengerView {
  const PassengerView({
    this.status = PassengerStatus.loading,
    this.vehicles = const [],
    this.targetVeh,
    this.route = const [],
    this.eta,
  });

  final PassengerStatus status;

  /// Up to 3 vehicles approaching on the chosen line.
  final List<VehicleView> vehicles;

  /// The vehicle the ETA card refers to (the closest one).
  final int? targetVeh;
  final List<GeoPoint> route;
  final EtaUpdate? eta;
}

/// Passenger-side flow for one line: /cercanos -> subscribe (max 3) -> /ruta for the closest -> ETA on every Pos.
/// Asks for a new route on deviation (rate limited) and for new vehicles when the target leaves or passes by.
class PassengerSession {
  PassengerSession({
    required this.api,
    required this.feed,
    required this.line,
    required GeoPoint user,
    this.maxVehicles = 3,
    this.minRerouteInterval = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _user = user, // ignore: prefer_initializing_formals (named params cannot be private)
       _clock = clock ?? DateTime.now;

  final PassengerApi api;
  final LiveFeed feed;
  final String line;
  final int maxVehicles;
  final Duration minRerouteInterval;
  final DateTime Function() _clock;
  GeoPoint _user;

  final _views = StreamController<PassengerView>.broadcast();
  final Map<int, VehicleView> _vehicles = {};
  final Set<String> _topics = {};
  StreamSubscription<MqttLinkMessage>? _sub;
  int? _target;
  List<GeoPoint> _route = const [];
  EtaEstimator? _eta;
  EtaUpdate? _lastEta;
  DateTime? _lastRouteAt;
  bool _routing = false, _refreshing = false, _closed = false;

  /// The target got within arrival distance at some point (sticky until the target changes).
  bool _arrived = false;

  /// Vehicles /ruta reported as not live; not tracked again in this session.
  final Set<int> _skip = {};
  PassengerView _view = const PassengerView();

  Stream<PassengerView> get views => _views.stream;
  PassengerView get view => _view;
  GeoPoint get user => _user;

  Future<void> start() async {
    _sub ??= feed.messages.listen(_onMessage);
    await refresh();
  }

  /// New /cercanos query: resubscribes to the (new) closest vehicles. Also used when the passenger moved.
  Future<void> refresh({GeoPoint? user}) async {
    if (_refreshing || _closed) return;
    _refreshing = true;
    if (user != null) _user = user;
    try {
      final nearby = await api.nearby(line, _user);
      final keep = nearby.where((n) => !_skip.contains(n.veh)).take(maxVehicles).toList();
      final wanted = {for (final n in keep) liveTopic(line, n.veh)};
      for (final t in _topics.difference(wanted)) {
        feed.unsubscribe(t);
      }
      _vehicles.removeWhere((veh, _) => !wanted.contains(liveTopic(line, veh)));
      for (final n in keep) {
        _vehicles[n.veh] = VehicleView(
          veh: n.veh,
          at: GeoPoint.e6(n.lat, n.lon),
          headingDeg: n.hdg * 2.0,
          speedKmh: n.spd.toDouble(),
          ts: n.ts,
        );
      }
      for (final t in wanted.difference(_topics)) {
        await feed.subscribe(t);
      }
      _topics
        ..clear()
        ..addAll(wanted);
      if (keep.isEmpty) {
        _setTarget(null);
        _emit(PassengerStatus.noVehicles);
        return;
      }
      if (_target != keep.first.veh) {
        _setTarget(keep.first.veh);
        await _fetchRoute();
      }
      _emit(PassengerStatus.tracking);
    } catch (_) {
      _emit(_vehicles.isEmpty ? PassengerStatus.error : _view.status);
    } finally {
      _refreshing = false;
    }
  }

  /// Unsubscribes everything (app to background); [start] again on resume.
  Future<void> stop() async {
    for (final t in _topics) {
      feed.unsubscribe(t);
    }
    _topics.clear();
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> close() async {
    _closed = true;
    await stop();
    await _views.close();
  }

  void _setTarget(int? veh) {
    _target = veh;
    _route = const [];
    _eta = null;
    _lastEta = null;
    _arrived = false;
  }

  Future<void> _fetchRoute() async {
    final veh = _target;
    if (veh == null || _routing) return;
    _routing = true;
    _lastRouteAt = _clock();
    try {
      final r = await api.route(veh, _user);
      if (veh != _target) return;
      if (r == null) {
        // Vehicle no longer live or unreachable: skip it and look for others once this refresh ends.
        _skip.add(veh);
        _vehicles.remove(veh);
        _setTarget(null);
        Timer.run(() => unawaited(refresh()));
        return;
      }
      _route = decodePolyline(r.polyline);
      _eta = _route.length >= 2 ? EtaEstimator(_route) : null;
      final v = _vehicles[veh];
      if (v != null) _lastEta = _eta?.update(v.at, v.ts, reportedKmh: v.speedKmh);
    } catch (_) {
      // Keep the previous route; retried on the next deviation.
    } finally {
      _routing = false;
    }
  }

  void _onMessage(MqttLinkMessage m) {
    final parts = m.topic.split('/');
    if (parts.length != 3 || parts[1] != line) return;
    final veh = int.tryParse(parts[2]);
    if (veh == null || !_vehicles.containsKey(veh)) return;

    if (m.payload.isEmpty) {
      // Out of service (or Last Will): drop it; if it was the target, pick another.
      _vehicles.remove(veh);
      feed.unsubscribe(m.topic);
      _topics.remove(m.topic);
      if (veh == _target) {
        _setTarget(null);
        unawaited(refresh());
      }
      _emit(_vehicles.isEmpty ? PassengerStatus.noVehicles : PassengerStatus.tracking);
      return;
    }

    final Pos p;
    try {
      p = Pos.fromBuffer(m.payload);
    } catch (_) {
      return;
    }
    final prev = _vehicles[veh];
    if (prev != null && p.ts <= prev.ts) return; // retained replay or out of order
    final v = VehicleView(
      veh: veh,
      at: GeoPoint.e6(p.lat, p.lon),
      headingDeg: p.hdg * 2.0,
      speedKmh: p.spd.toDouble(),
      ts: p.ts,
    );
    _vehicles[veh] = v;

    if (veh == _target && _eta != null) {
      final u = _eta!.update(v.at, v.ts, reportedKmh: v.speedKmh);
      _lastEta = u;
      _arrived |= u.arrived;
      if (u.needsReroute) {
        if (_arrived) {
          // It passed the passenger: switch to the next approaching vehicle.
          _setTarget(null);
          unawaited(refresh());
        } else if (_lastRouteAt == null || _clock().difference(_lastRouteAt!) >= minRerouteInterval) {
          unawaited(_fetchRoute().then((_) => _emit(PassengerStatus.tracking)));
        }
      }
    }
    _emit(PassengerStatus.tracking);
  }

  void _emit(PassengerStatus status) {
    if (_closed) return;
    final sorted = _vehicles.values.toList()
      ..sort((a, b) => distanceMeters(a.at, _user).compareTo(distanceMeters(b.at, _user)));
    _view = PassengerView(status: status, vehicles: sorted, targetVeh: _target, route: _route, eta: _lastEta);
    _views.add(_view);
  }
}
