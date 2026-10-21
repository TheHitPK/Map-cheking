import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import 'supervisor_models.dart';

final supervisorApiProvider = Provider<SupervisorApi>((ref) => SupervisorApi(
      ref.watch(apiClientProvider),
      onUnauthorized: () => ref.read(authProvider.notifier).expire(),
    ));

class SupervisorApi {
  SupervisorApi(this._api, {required this.onUnauthorized});

  final ApiClient _api;
  final Future<void> Function() onUnauthorized;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      if (e.isUnauthorized) await onUnauthorized();
      rethrow;
    }
  }

  List<Map<String, dynamic>> _list(dynamic json) => (json as List).cast<Map<String, dynamic>>();

  Future<List<Worksite>> worksites() => _guard(() async => _list(await _api.get('/worksites')).map(Worksite.fromJson).toList());

  Future<Worksite> saveWorksite({int? id, required Map<String, dynamic> body}) => _guard(() async => Worksite.fromJson(
      (id == null ? await _api.post('/worksites', body) : await _api.put('/worksites/$id', body)) as Map<String, dynamic>));

  Future<List<Employee>> employees() => _guard(() async => _list(await _api.get('/employees')).map(Employee.fromJson).toList());

  Future<Employee> createEmployee(Map<String, dynamic> body) =>
      _guard(() async => Employee.fromJson(await _api.post('/employees', body) as Map<String, dynamic>));

  Future<Employee> updateEmployee(int id, Map<String, dynamic> body) =>
      _guard(() async => Employee.fromJson(await _api.put('/employees/$id', body) as Map<String, dynamic>));

  Future<void> resetPassword(int id, String password) => _guard(() => _api.put('/employees/$id/password', {'password': password}));

  Future<List<Shift>> shifts() => _guard(() async => _list(await _api.get('/schedules')).map(Shift.fromJson).toList());

  Future<Shift> assignShift(int employeeId, Map<String, dynamic> body) =>
      _guard(() async => Shift.fromJson(await _api.put('/schedules/$employeeId', body) as Map<String, dynamic>));

  Future<void> removeShift(int employeeId) => _guard(() => _api.delete('/schedules/$employeeId'));

  Future<List<DailyRow>> daily(DateTime date, int? worksiteId) => _guard(() async => _list(await _api.get('/attendance/daily',
          query: {'date': Fmt.isoDate(date), if (worksiteId != null) 'worksiteId': '$worksiteId'}))
      .map(DailyRow.fromJson)
      .toList());

  Future<List<MarkRow>> marks(DateTime from, DateTime to, int? worksiteId) => _guard(() async => _list(await _api.get(
          '/attendance/marks',
          query: {'from': Fmt.isoDate(from), 'to': Fmt.isoDate(to), if (worksiteId != null) 'worksiteId': '$worksiteId'}))
      .map(MarkRow.fromJson)
      .toList());
}

// Read models. Mutations call the API and then invalidate the affected provider.

final worksitesProvider = FutureProvider<List<Worksite>>((ref) => ref.watch(supervisorApiProvider).worksites());

final employeesProvider = FutureProvider<List<Employee>>((ref) => ref.watch(supervisorApiProvider).employees());

final shiftsProvider = FutureProvider<List<Shift>>((ref) => ref.watch(supervisorApiProvider).shifts());

typedef DailyQuery = ({DateTime date, int? worksiteId});

final dailyProvider = FutureProvider.family<List<DailyRow>, DailyQuery>(
    (ref, q) => ref.watch(supervisorApiProvider).daily(q.date, q.worksiteId));

typedef MarksQuery = ({DateTime from, DateTime to, int? worksiteId});

final marksProvider = FutureProvider.family<List<MarkRow>, MarksQuery>(
    (ref, q) => ref.watch(supervisorApiProvider).marks(q.from, q.to, q.worksiteId));
