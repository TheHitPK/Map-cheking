import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../common/tls.dart';
import '../config.dart';
import 'driver_store.dart';

/// Entry point of the foreground-service isolate.
@pragma('vm:entry-point')
void startDriverTask() => FlutterForegroundTask.setTaskHandler(DriverTaskHandler());

/// Messages from the UI isolate.
const stopCommand = 'stop';

/// Runs while "En servicio": GPS -> DriverSession -> MQTT, with offline queue and token renewal.
class DriverTaskHandler extends TaskHandler {
  static const tokenRenewBefore = Duration(minutes: 5);
  static const maxBackoff = Duration(seconds: 60);

  final usage = DataUsage();
  AppDb? _db;
  ApiClient? _api;
  MqttLink? _link;
  DriverSession? _session;
  DriverCredentials? _creds;
  StreamSubscription<Position>? _gps;
  StreamSubscription<void>? _drops;
  Timer? _renew, _retry;
  Duration _backoff = const Duration(seconds: 1);
  bool _connecting = false, _stopping = false, _reading = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final db = _db = AppDb.open();
    final store = DriverStore(db);
    final creds = _creds = await store.credentials();
    final line = await store.line();
    if (creds == null || line == null) {
      FlutterForegroundTask.sendDataToMain({'error': 'Falta la unidad, el PIN o la línea'});
      await FlutterForegroundTask.stopService();
      return;
    }
    final tls = await storedSecurityContext(db);
    _api = ApiClient(Uri.parse(AppConfig.apiUrl), http: httpClientFor(tls), usage: usage);
    final link = _link = MqttLink(
      host: AppConfig.mqttHost,
      port: AppConfig.mqttPort,
      secure: AppConfig.mqttTls,
      securityContext: tls,
      clientId: 'veh-${creds.veh}',
      usage: usage,
    );
    _session = DriverSession(veh: creds.veh, line: line, publisher: link, db: db);
    _drops = link.disconnects.listen((_) => _scheduleReconnect());
    unawaited(_connect());

    _gps = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.medium, distanceFilter: 50),
    ).listen(_onPosition, onError: (Object _) {});
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // distanceFilter 50 sends nothing while slow or stopped: read a fix when the 15 s / 60 s rule is due.
    final session = _session;
    if (session != null && !_reading && session.policy.dueByTime(DateTime.now())) {
      _reading = true;
      Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 10)),
      ).then(_onPosition, onError: (Object _) {}).whenComplete(() => _reading = false);
    }
    unawaited(_report());
  }

  @override
  void onReceiveData(Object data) {
    if (data == stopCommand) unawaited(_goOffline());
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _gps?.cancel();
    await _drops?.cancel();
    _renew?.cancel();
    _retry?.cancel();
    // Killed without "Fuera de servicio": still try to clear the retained position (Last Will covers a hard drop).
    if (!_stopping) _session?.goOffline();
    await _link?.dispose();
    _api?.close();
    await _db?.close();
  }

  Future<void> _onPosition(Position p) async {
    await _session?.onFix(DriverFix(
      time: p.timestamp,
      at: GeoPoint(p.latitude, p.longitude),
      speedKmh: math.max(0, p.speed * 3.6),
      headingDeg: p.heading < 0 ? 0 : p.heading,
    ));
  }

  Future<void> _connect() async {
    final api = _api, link = _link, session = _session, creds = _creds;
    if (_connecting || _stopping || api == null || link == null || session == null || creds == null) return;
    _connecting = true;
    try {
      final token = await api.driverToken(veh: creds.veh, pin: creds.pin, line: session.line);
      await link.connectWith(token, fallbackUsername: 'veh:${creds.veh}', willTopic: liveTopic(session.line, creds.veh));
      _backoff = const Duration(seconds: 1);
      final exp = DateTime.fromMillisecondsSinceEpoch(token.exp * 1000);
      final renewIn = exp.difference(DateTime.now()) - tokenRenewBefore;
      _renew?.cancel();
      _renew = Timer(renewIn.isNegative ? Duration.zero : renewIn, () => unawaited(_connect()));
      await session.onConnected();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 404) {
        FlutterForegroundTask.sendDataToMain({'error': e.statusCode == 401 ? 'Unidad o PIN incorrecto' : 'Línea no existe'});
        _connecting = false;
        await _goOffline();
        return;
      }
      _scheduleReconnect(e.statusCode == 429 ? const Duration(minutes: 15) : null);
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _connecting = false;
      unawaited(_report());
    }
  }

  void _scheduleReconnect([Duration? delay]) {
    if (_stopping) return;
    _retry?.cancel();
    _retry = Timer(delay ?? _backoff, () => unawaited(_connect()));
    final next = _backoff * 2;
    _backoff = next > maxBackoff ? maxBackoff : next;
  }

  Future<void> _goOffline() async {
    _stopping = true;
    _session?.goOffline();
    await _link?.disconnect();
    await FlutterForegroundTask.stopService();
  }

  Future<void> _report() async {
    final session = _session, link = _link;
    if (session == null || link == null) return;
    final pending = await session.pendingCount();
    FlutterForegroundTask.sendDataToMain({
      'connected': link.connected,
      'pending': pending,
      'published': session.publishedLive,
      'kb': usage.totalKb,
    });
    FlutterForegroundTask.updateService(
      notificationText: link.connected
          ? 'Enviando ubicación · línea ${session.line}'
          : 'Sin señal · $pending posiciones guardadas',
    );
  }
}
