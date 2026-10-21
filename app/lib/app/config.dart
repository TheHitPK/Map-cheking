import 'package:flutter/foundation.dart';

/// Which app this build is. Set by the entry point (main_trabajador / main_supervisor).
enum AppRole { worker, supervisor }

class AppConfig {
  const AppConfig._();

  /// Backend base URL: `--dart-define=API_URL=https://api.example.com`.
  /// Defaults: Android emulator → host machine; web → same host, port 8080.
  static String get apiUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://${Uri.base.host}:8080';
    return 'http://10.0.2.2:8080';
  }

  /// Long enough for a sleeping free-tier server to wake up (Render: 30–60 s). Marks never wait on it: they are queued first.
  static const requestTimeout = Duration(seconds: 60);
}
