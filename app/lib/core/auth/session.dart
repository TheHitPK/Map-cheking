import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  const Session({
    required this.token,
    required this.expiresAt,
    required this.employeeId,
    required this.fullName,
    required this.role,
  });

  final String token;
  final DateTime expiresAt;
  final int employeeId;
  final String fullName;

  /// `WORKER` or `SUPERVISOR`.
  final String role;

  bool get expired => DateTime.now().isAfter(expiresAt);

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        token: j['token'] as String,
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        employeeId: (j['employeeId'] as num).toInt(),
        fullName: j['fullName'] as String,
        role: j['role'] as String,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'employeeId': employeeId,
        'fullName': fullName,
        'role': role,
      };
}

/// Persists the session in the platform keystore (Android Keystore; WebCrypto on web).
class SessionStore {
  SessionStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'session';
  final FlutterSecureStorage _storage;

  Future<Session?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final s = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return s.expired ? null : s;
    } catch (_) {
      return null; // corrupted or unreadable after a reinstall: just ask to log in again
    }
  }

  Future<void> write(Session s) => _storage.write(key: _key, value: jsonEncode(s.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}
