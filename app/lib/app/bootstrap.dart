import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_controller.dart';
import '../core/strings.dart';
import '../features/auth/login_screen.dart';
import '../features/supervisor/presentation/supervisor_shell.dart';
import '../features/worker/presentation/location_disclosure.dart';
import '../features/worker/presentation/worker_shell.dart';
import 'theme.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(
    // Errors are shown with a retry button; no silent automatic retries.
    retry: (retryCount, error) => null,
    child: MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('en', 'US'),
      supportedLocales: const [Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _AuthGate(),
    ),
  ));
}

/// Signed out → login; then the role from the token decides the home.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return switch (auth) {
      // A crew session restored on the web (kept from before) is not usable there: ask to sign in again.
      AsyncData(value: final s?) when s.isWorker && !kIsWeb => const LocationDisclosureGate(child: WorkerShell()),
      AsyncData(value: final s?) when !s.isWorker => const SupervisorShell(),
      AsyncData() || AsyncError() => const LoginScreen(),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}
