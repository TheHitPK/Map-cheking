import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:core/proto.dart' as pb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../common/lines_cache.dart';
import '../config.dart';

/// Center of Maracaibo, used until the passenger's position is known.
const maracaibo = GeoPoint(10.6427, -71.6125);

class PasajeroState {
  const PasajeroState({
    this.loading = true,
    this.lines = const [],
    this.line,
    this.user,
    this.view = const PassengerView(),
    this.kb = 0,
    this.error,
  });

  final bool loading;
  final List<pb.Line> lines;
  final String? line;
  final GeoPoint? user;
  final PassengerView view;
  final double kb;
  final String? error;

  PasajeroState copyWith({
    bool? loading,
    List<pb.Line>? lines,
    String? line,
    GeoPoint? user,
    PassengerView? view,
    double? kb,
    String? error,
    bool clearError = false,
  }) =>
      PasajeroState(
        loading: loading ?? this.loading,
        lines: lines ?? this.lines,
        line: line ?? this.line,
        user: user ?? this.user,
        view: view ?? this.view,
        kb: kb ?? this.kb,
        error: clearError ? null : (error ?? this.error),
      );
}

final pasajeroProvider = NotifierProvider<PasajeroController, PasajeroState>(PasajeroController.new);

/// Passenger flow: location -> /cercanos -> MQTT (max 3) -> /ruta -> ETA on the phone.
/// MQTT is disconnected while the app is in background (data + battery).
class PasajeroController extends Notifier<PasajeroState> with WidgetsBindingObserver {
  static const tokenRenewBefore = Duration(minutes: 5);

  late final AppDb _db = AppDb.open();
  late final ApiClient _api = ApiClient(Uri.parse(AppConfig.apiUrl));
  late final LinesCache _linesCache = LinesCache(_db, _api);
  late final MqttLink _link = MqttLink(
    host: AppConfig.mqttHost,
    port: AppConfig.mqttPort,
    secure: AppConfig.mqttTls,
    clientId: 'pas-${math.Random().nextInt(1 << 31).toRadixString(36)}',
    usage: _api.usage, // one counter for the whole session
  );
  PassengerSession? _session;
  StreamSubscription<PassengerView>? _views;
  StreamSubscription<void>? _drops;
  DateTime? _tokenExp;
  bool _foreground = true;

  @override
  PasajeroState build() {
    WidgetsBinding.instance.addObserver(this);
    _drops = _link.disconnects.listen((_) => unawaited(_reconnect()));
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      unawaited(_dispose());
    });
    unawaited(_load());
    return const PasajeroState();
  }

  Future<void> _load() async {
    final cached = await _linesCache.cached();
    final line = await _db.getString('pas_line');
    state = state.copyWith(loading: false, lines: cached, line: line);
    await Future.wait([_refreshLines(), _locate()]);
    if (state.line != null) await _startSession();
  }

  Future<void> _refreshLines() async {
    try {
      state = state.copyWith(lines: await _linesCache.refresh(), kb: _kb);
    } catch (_) {
      if (state.lines.isEmpty) state = state.copyWith(error: 'Sin conexión: no se pudieron cargar las líneas');
    }
  }

  double get _kb => _api.usage.totalKb;

  Future<void> selectLine(String line) async {
    if (line == state.line) return;
    state = state.copyWith(line: line, view: const PassengerView(), clearError: true);
    await _db.putString('pas_line', line);
    await _startSession();
  }

  /// "Actualizar": new position and new /cercanos.
  Future<void> refresh() async {
    await _locate();
    await _session?.refresh(user: state.user);
  }

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = state.copyWith(error: 'Activa el GPS para ver qué tan lejos viene la unidad');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        state = state.copyWith(error: 'Sin permiso de ubicación');
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)),
      );
      final user = GeoPoint(p.latitude, p.longitude);
      final inArea = inServiceArea(user);
      state = state.copyWith(user: user, error: inArea ? null : 'Estás fuera del área de servicio (Maracaibo)', clearError: inArea);
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) state = state.copyWith(user: GeoPoint(last.latitude, last.longitude));
    }
  }

  Future<void> _ensureConnected() async {
    final exp = _tokenExp;
    if (_link.connected && exp != null && exp.difference(DateTime.now()) > tokenRenewBefore) return;
    final token = await _api.passengerToken();
    _tokenExp = DateTime.fromMillisecondsSinceEpoch(token.exp * 1000);
    await _link.connect(jwt: token.jwt);
  }

  Future<void> _startSession() async {
    final line = state.line, user = state.user;
    if (line == null || user == null || !_foreground) return;
    await _views?.cancel();
    await _session?.close();
    try {
      await _ensureConnected();
    } catch (_) {
      state = state.copyWith(error: 'Sin conexión. Toca "Actualizar" para reintentar', kb: _kb);
      return;
    }
    final session = _session = PassengerSession(api: _api, feed: _link, line: line, user: user);
    _views = session.views.listen((v) => state = state.copyWith(view: v, kb: _kb));
    await session.start();
    state = state.copyWith(kb: _kb);
  }

  Future<void> _reconnect() async {
    if (!_foreground) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    await _startSession();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lifecycle = state; // `state` shadows the Notifier state here
    if (lifecycle == AppLifecycleState.paused || lifecycle == AppLifecycleState.hidden) {
      if (!_foreground) return;
      _foreground = false;
      unawaited(_session?.stop());
      unawaited(_link.disconnect());
    } else if (lifecycle == AppLifecycleState.resumed && !_foreground) {
      _foreground = true;
      unawaited(_locate().then((_) => _startSession()));
    }
  }

  Future<void> _dispose() async {
    await _drops?.cancel();
    await _views?.cancel();
    await _session?.close();
    await _link.dispose();
    _api.close();
    await _db.close();
  }
}
