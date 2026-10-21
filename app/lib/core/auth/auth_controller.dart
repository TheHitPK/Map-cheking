import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../api/api_client.dart';
import '../strings.dart';
import 'session.dart';

/// Overridden by each entry point.
final appRoleProvider = Provider<AppRole>((ref) => throw UnimplementedError('appRoleProvider not overridden'));

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenProvider: () => ref.read(authProvider).value?.token);
});

/// Message shown on the login screen after an automatic logout (expired session).
final logoutReasonProvider = NotifierProvider<LogoutReason, String?>(LogoutReason.new);

class LogoutReason extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? message) => state = message;
}

final authProvider = AsyncNotifierProvider<AuthController, Session?>(AuthController.new);

class AuthController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() => ref.read(sessionStoreProvider).read();

  Future<void> login(String document, String password) async {
    final api = ref.read(apiClientProvider);
    final json = await api.post('/auth/login', {'document': document.trim(), 'password': password});
    final session = Session.fromJson(json as Map<String, dynamic>);
    final expected = ref.read(appRoleProvider) == AppRole.worker ? 'WORKER' : 'SUPERVISOR';
    if (session.role != expected) {
      throw ApiException(expected == 'WORKER' ? S.supervisorAccountInWorkerApp : S.workerAccountInSupervisorApp);
    }
    await ref.read(sessionStoreProvider).write(session);
    ref.read(logoutReasonProvider.notifier).set(null);
    state = AsyncData(session);
  }

  Future<void> logout({String? reason}) async {
    await ref.read(sessionStoreProvider).clear();
    ref.read(logoutReasonProvider.notifier).set(reason);
    state = const AsyncData(null);
  }

  /// Call when any request returns 401.
  Future<void> expire() => logout(reason: S.sessionExpired);
}
