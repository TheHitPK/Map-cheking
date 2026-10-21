// Renders key screens to PNG for design review. Run from app/:
//   flutter test tool/screens_preview_test.dart --dart-define=OUT=<dir> --dart-define=FONTS=<flutter>/bin/cache/artifacts/material_fonts
import 'dart:io';
import 'dart:ui' as ui;

import 'package:asistencia/app/config.dart';
import 'package:asistencia/app/theme.dart';
import 'package:asistencia/core/auth/auth_controller.dart';
import 'package:asistencia/core/auth/session.dart';
import 'package:asistencia/core/models.dart';
import 'package:asistencia/features/auth/login_screen.dart';
import 'package:asistencia/features/supervisor/data/supervisor_api.dart';
import 'package:asistencia/features/supervisor/data/supervisor_models.dart';
import 'package:asistencia/features/supervisor/presentation/supervisor_shell.dart';
import 'package:asistencia/features/worker/application/worker_controller.dart';
import 'package:asistencia/features/worker/data/location_service.dart';
import 'package:asistencia/features/worker/presentation/location_disclosure.dart';
import 'package:asistencia/features/worker/presentation/worker_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _out = String.fromEnvironment('OUT');
const _fonts = String.fromEnvironment('FONTS');

final _session = Session(
    token: 't', expiresAt: DateTime(2100), employeeId: 1, fullName: 'Marcus Johnson', role: 'WORKER');

class _Auth extends AuthController {
  @override
  Future<Session?> build() async => _session;
}

class _NoAuth extends AuthController {
  @override
  Future<Session?> build() async => null;
}

class _Worker extends WorkerController {
  _Worker(this.s);

  final WorkerState s;

  @override
  WorkerState build() => s;
}

class _Disclosure extends LocationDisclosure {
  @override
  Future<bool> build() async => false;
}

final _site = Worksite(id: 1, name: 'Riverside Medical Center', address: '2100 Riverside Dr, Austin, TX', lat: 30.2500, lon: -97.7300, radiusMeters: 100, active: true);
final _now = DateTime.now();

Mark _mark(String type, String status, int minutesAgo, {String? message}) => Mark(
    id: minutesAgo,
    clientId: '$minutesAgo',
    type: type,
    status: status,
    rejection: message == null ? null : 'OUT_OF_ZONE',
    message: message,
    recordedAt: _now.subtract(Duration(minutes: minutesAgo)),
    distanceMeters: 40,
    accuracyMeters: 8,
    deferred: false);

final _today = TodayInfo(
  fullName: 'Marcus Johnson',
  worksite: _site,
  shift: const ShiftInfo(start: '07:00:00', end: '15:30:00', days: ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'], graceMinutes: 10),
  todayStart: DateTime(_now.year, _now.month, _now.day, 7),
  todayEnd: DateTime(_now.year, _now.month, _now.day, 15, 30),
  marks: [_mark('IN', 'REJECTED', 70, message: "You're outside the job site area."), _mark('IN', 'ON_TIME', 62)],
  next: 'OUT',
);

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(File('$_fonts/$f').readAsBytes().then((b) => b.buffer.asByteData()));
    }
    await loader.load();
  }

  await load('Roboto', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf']);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

Future<void> _shot(WidgetTester tester, String name, Widget home, List overrides,
    {Size size = const Size(400, 860), Brightness brightness = Brightness.light}) async {
  final key = GlobalKey();
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    retry: (_, _) => null,
    overrides: [...overrides],
    child: RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
        home: home,
      ),
    ),
  ));
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = boundary.toImageSync(pixelRatio: 2);
  await tester.runAsync(() async {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$_out/$name.png').writeAsBytes(png!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    await Directory(_out).create(recursive: true);
  });

  testWidgets('screens', (tester) async {
    final worker = [appRoleProvider.overrideWithValue(AppRole.worker), authProvider.overrideWith(_Auth.new)];

    await _shot(tester, '1_login_worker', const LoginScreen(), [appRoleProvider.overrideWithValue(AppRole.worker), authProvider.overrideWith(_NoAuth.new)]);
    await _shot(tester, '2_disclosure', const LocationDisclosureGate(child: SizedBox()), [...worker, locationDisclosureProvider.overrideWith(_Disclosure.new)]);

    final onSite = WorkerState(
      today: _today,
      loading: false,
      fix: Fix(lat: 30.2503, lon: -97.7300, accuracyMeters: 6, mocked: false, time: _now),
      outcome: const MarkOutcome(OutcomeKind.accepted, "You're punched in", 'On time. Nice work!'),
    );
    await _shot(tester, '3_worker_on_site', const WorkerHomeScreen(), [...worker, workerControllerProvider.overrideWith(() => _Worker(onSite))]);

    final offSite = WorkerState(
      today: TodayInfo(fullName: _today.fullName, worksite: _site, shift: _today.shift, todayStart: _today.todayStart,
          todayEnd: _today.todayEnd, marks: const [], next: 'IN'),
      loading: false,
      fix: Fix(lat: 30.2560, lon: -97.7300, accuracyMeters: 9, mocked: false, time: _now),
      outcome: const MarkOutcome(OutcomeKind.rejected, 'Punch-in not recorded', "You're outside the job site area."),
    );
    await _shot(tester, '4_worker_off_site_dark', const WorkerHomeScreen(),
        [...worker, workerControllerProvider.overrideWith(() => _Worker(offSite))], brightness: Brightness.dark);

    Mark m(String t, String s, int h, int min) =>
        Mark(id: h * 60 + min, clientId: '$h$min', type: t, status: s, rejection: null, message: null,
            recordedAt: DateTime(_now.year, _now.month, _now.day, h, min), distanceMeters: 35, accuracyMeters: 7, deferred: false);
    DailyRow row(String name, String state, {Mark? inMark, Mark? outMark, bool onSite = false, int rejected = 0}) => DailyRow(
        employeeId: name.hashCode, fullName: name, document: 'E-1001', worksiteId: 1, worksiteName: _site.name,
        shiftStart: '07:00:00', shiftEnd: '15:30:00', state: state, inMark: inMark, outMark: outMark,
        earlyLeave: false, onSite: onSite, rejectedAttempts: rejected);
    final rows = [
      row('Ana Rodriguez', 'ON_TIME', inMark: m('IN', 'ON_TIME', 6, 52), onSite: true),
      row('Darnell Brooks', 'LATE', inMark: m('IN', 'LATE', 7, 24), onSite: true, rejected: 1),
      row('Kevin Walsh', 'ABSENT'),
      row('Marcus Johnson', 'ON_TIME', inMark: m('IN', 'ON_TIME', 6, 58), outMark: m('OUT', 'ON_TIME', 15, 34)),
    ];
    final supervisor = [
      appRoleProvider.overrideWithValue(AppRole.supervisor),
      authProvider.overrideWith(_Auth.new),
      dailyProvider.overrideWith((ref, q) async => rows),
      worksitesProvider.overrideWith((ref) async => [_site]),
    ];
    await _shot(tester, '5_supervisor_web', const SupervisorShell(), supervisor, size: const Size(1280, 800));
    await _shot(tester, '6_supervisor_phone', const SupervisorShell(), supervisor);
  });
}
