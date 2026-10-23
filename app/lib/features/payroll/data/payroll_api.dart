import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/format.dart';
import 'payroll_models.dart';

final payrollApiProvider = Provider<PayrollApi>((ref) => PayrollApi(
      ref.watch(apiClientProvider),
      onUnauthorized: () => ref.read(authProvider.notifier).expire(),
    ));

class PayrollApi {
  PayrollApi(this._api, {required this.onUnauthorized});

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

  Future<MyPay> myPay() => _guard(() async => MyPay.fromJson(await _api.get('/me/pay') as Map<String, dynamic>));

  Future<Payroll> week(DateTime anyDay) => _guard(() async =>
      Payroll.fromJson(await _api.get('/payroll', query: {'date': Fmt.isoDate(anyDay)}) as Map<String, dynamic>));

  Future<Payroll> markPaid(DateTime periodStart, DateTime paidOn) => _guard(() async => Payroll.fromJson(
      await _api.post('/payroll/${Fmt.isoDate(periodStart)}/pay', {'paidOn': Fmt.isoDate(paidOn)}) as Map<String, dynamic>));
}

final myPayProvider = FutureProvider<MyPay>((ref) => ref.watch(payrollApiProvider).myPay());

/// Keyed by the week's Monday.
final payrollProvider = FutureProvider.family<Payroll, DateTime>((ref, monday) => ref.watch(payrollApiProvider).week(monday));

/// Monday of the week containing [day] (pay periods run Monday to Sunday).
DateTime mondayOf(DateTime day) => DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));
