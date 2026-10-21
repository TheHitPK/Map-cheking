import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import 'config.dart';
import 'theme.dart';

/// Shared entry: one app per role, the home screen is chosen by the entry point.
void bootstrap({required AppRole role, required String title, required WidgetBuilder home}) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(
    // Errors are shown with a retry button; no silent automatic retries.
    retry: (retryCount, error) => null,
    overrides: [appRoleProvider.overrideWithValue(role)],
    child: MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('en', 'US'),
      supportedLocales: const [Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: _AuthGate(home: home),
    ),
  ));
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate({required this.home});

  final WidgetBuilder home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return switch (auth) {
      AsyncData(value: _?) => home(context),
      AsyncData() || AsyncError() => const LoginScreen(),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}
