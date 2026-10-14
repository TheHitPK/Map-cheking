import 'dart:async';

import 'package:core/core.dart';
import 'package:core/proto.dart' as pb;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../common/lines_cache.dart';
import '../common/tls.dart';
import '../config.dart';
import 'driver_store.dart';
import 'driver_task.dart';

class ChoferState {
  const ChoferState({
    this.loading = true,
    this.lines = const [],
    this.line,
    this.veh,
    this.inService = false,
    this.busy = false,
    this.connected = false,
    this.pending = 0,
    this.kb = 0,
    this.error,
  });

  final bool loading;
  final List<pb.Line> lines;
  final String? line;

  /// Saved unit; null until the first successful login.
  final int? veh;
  final bool inService;
  final bool busy;
  final bool connected;
  final int pending;

  /// Session data use: UI isolate (HTTP) + service isolate (HTTP + MQTT).
  final double kb;
  final String? error;

  ChoferState copyWith({
    bool? loading,
    List<pb.Line>? lines,
    String? line,
    int? veh,
    bool clearVeh = false,
    bool? inService,
    bool? busy,
    bool? connected,
    int? pending,
    double? kb,
    String? error,
    bool clearError = false,
  }) =>
      ChoferState(
        loading: loading ?? this.loading,
        lines: lines ?? this.lines,
        line: line ?? this.line,
        veh: clearVeh ? null : (veh ?? this.veh),
        inService: inService ?? this.inService,
        busy: busy ?? this.busy,
        connected: connected ?? this.connected,
        pending: pending ?? this.pending,
        kb: kb ?? this.kb,
        error: clearError ? null : (error ?? this.error),
      );
}

final choferProvider = NotifierProvider<ChoferController, ChoferState>(ChoferController.new);

class ChoferController extends Notifier<ChoferState> {
  late final AppDb _db = AppDb.open();
  late final DriverStore _store = DriverStore(_db);
  ApiClient? _apiClient; // created in _load, once the TLS trust is known
  ApiClient get _api => _apiClient!;
  late final LinesCache _lines = LinesCache(_db, _api);
  double _taskKb = 0;

  @override
  ChoferState build() {
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    ref.onDispose(() {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
      _apiClient?.close();
      unawaited(_db.close());
    });
    unawaited(_load());
    return const ChoferState();
  }

  Future<void> _load() async {
    _apiClient = ApiClient(Uri.parse(AppConfig.apiUrl), http: httpClientFor(await uiSecurityContext(_db)));
    final creds = await _store.credentials();
    final line = await _store.line();
    final cached = await _lines.cached();
    state = state.copyWith(
      loading: false,
      veh: creds?.veh,
      line: line,
      lines: cached,
      inService: await FlutterForegroundTask.isRunningService,
    );
    try {
      final lines = await _lines.refresh();
      state = state.copyWith(lines: lines, kb: _kb);
    } catch (_) {
      if (state.lines.isEmpty) state = state.copyWith(error: 'Sin conexión: no se pudieron cargar las líneas');
    }
  }

  double get _kb => (_apiClient?.usage.totalKb ?? 0) + _taskKb;

  void selectLine(String line) {
    if (state.inService) return;
    state = state.copyWith(line: line, clearError: true);
    unawaited(_store.saveLine(line));
  }

  /// [veh]/[pin] only needed the first time; they are checked against the backend before saving.
  Future<void> startService({int? veh, String? pin}) async {
    final line = state.line;
    if (line == null) {
      state = state.copyWith(error: 'Elige una línea');
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      if (veh != null && pin != null) {
        await _api.driverToken(veh: veh, pin: pin, line: line);
        await _store.saveCredentials(DriverCredentials(veh, pin));
        state = state.copyWith(veh: veh);
      }
      if (state.veh == null) {
        state = state.copyWith(error: 'Ingresa la unidad y el PIN');
        return;
      }
      final permissionError = await _ensurePermissions();
      if (permissionError != null) {
        state = state.copyWith(error: permissionError);
        return;
      }
      _initService();
      final result = await FlutterForegroundTask.startService(
        serviceId: 7,
        serviceTypes: [ForegroundServiceTypes.location],
        notificationTitle: 'En servicio · ${_lineName(line)}',
        notificationText: 'Conectando…',
        callback: startDriverTask,
      );
      state = state.copyWith(inService: result is ServiceRequestSuccess);
      if (result is ServiceRequestFailure) state = state.copyWith(error: 'No se pudo iniciar el servicio');
    } on ApiException catch (e) {
      state = state.copyWith(
        error: switch (e.statusCode) {
          401 => 'Unidad o PIN incorrecto',
          429 => 'Demasiados intentos. Espera 15 minutos',
          404 => 'Línea no existe',
          _ => 'Error del servidor (${e.statusCode})',
        },
      );
    } catch (_) {
      state = state.copyWith(error: 'Sin conexión. Intenta de nuevo');
    } finally {
      state = state.copyWith(busy: false, kb: _kb);
    }
  }

  Future<void> stopService() async {
    state = state.copyWith(busy: true);
    FlutterForegroundTask.sendDataToTask(stopCommand);
    // The task clears the retained position and stops itself; force it if it does not answer.
    await Future<void>.delayed(const Duration(seconds: 3));
    if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
    state = state.copyWith(inService: false, busy: false, connected: false);
  }

  Future<void> changeUnit() async {
    if (state.inService) return;
    await _store.clearCredentials();
    state = state.copyWith(clearVeh: true);
  }

  String _lineName(String id) => state.lines.where((l) => l.id == id).map((l) => l.name).firstOrNull ?? id;

  void _initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'en_servicio',
        channelName: 'En servicio',
        channelDescription: 'Ubicación compartida con los pasajeros',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<String?> _ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) return 'Activa el GPS del teléfono';
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return 'Sin permiso de ubicación';
    }
    if (await FlutterForegroundTask.checkNotificationPermission() != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    return null;
  }

  void _onTaskData(Object data) {
    if (data is! Map) return;
    if (data['error'] is String) {
      state = state.copyWith(error: data['error'] as String, inService: false, connected: false);
      return;
    }
    _taskKb = (data['kb'] as num?)?.toDouble() ?? _taskKb;
    state = state.copyWith(
      connected: data['connected'] == true,
      pending: (data['pending'] as num?)?.toInt() ?? 0,
      kb: _kb,
    );
  }
}
