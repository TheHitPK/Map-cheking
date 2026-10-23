import '../../../core/format.dart';

/// Gross pay for one week. Money in US cents, time in minutes.
class Pay {
  const Pay({required this.regularMinutes, required this.overtimeMinutes, this.hourlyRateCents, this.grossCents});

  final int regularMinutes;
  final int overtimeMinutes;

  /// Null while the rate is not set (then [grossCents] is null too).
  final int? hourlyRateCents;
  final int? grossCents;

  int get totalMinutes => regularMinutes + overtimeMinutes;

  factory Pay.fromJson(Map<String, dynamic> j) => Pay(
        regularMinutes: (j['regularMinutes'] as num).toInt(),
        overtimeMinutes: (j['overtimeMinutes'] as num).toInt(),
        hourlyRateCents: (j['hourlyRateCents'] as num?)?.toInt(),
        grossCents: (j['grossCents'] as num?)?.toInt(),
      );
}

typedef DayMinutes = ({DateTime date, int minutes});

List<DayMinutes> _days(dynamic json) => [
      for (final d in (json as List).cast<Map<String, dynamic>>())
        (date: Fmt.apiDate(d['date'] as String), minutes: (d['minutes'] as num).toInt()),
    ];

/// One week of a crew member's pay: the live estimate, or the frozen amount once paid.
class PayStub {
  const PayStub({
    required this.periodStart,
    required this.periodEnd,
    required this.paid,
    required this.payDate,
    required this.pay,
    required this.days,
    required this.missingPunchOuts,
    required this.punchedIn,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final bool paid;

  /// The day it was paid, or the expected payday.
  final DateTime payDate;
  final Pay pay;
  final List<DayMinutes> days;
  final int missingPunchOuts;
  final bool punchedIn;

  factory PayStub.fromJson(Map<String, dynamic> j) => PayStub(
        periodStart: Fmt.apiDate(j['periodStart'] as String),
        periodEnd: Fmt.apiDate(j['periodEnd'] as String),
        paid: j['paid'] as bool,
        payDate: Fmt.apiDate(j['payDate'] as String),
        pay: Pay.fromJson(j['pay'] as Map<String, dynamic>),
        days: _days(j['days']),
        missingPunchOuts: (j['missingPunchOuts'] as num).toInt(),
        punchedIn: j['punchedIn'] as bool,
      );
}

class PaidWeek {
  const PaidWeek({required this.periodStart, required this.periodEnd, required this.paidOn, required this.pay});

  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime paidOn;
  final Pay pay;

  factory PaidWeek.fromJson(Map<String, dynamic> j) => PaidWeek(
        periodStart: Fmt.apiDate(j['periodStart'] as String),
        periodEnd: Fmt.apiDate(j['periodEnd'] as String),
        paidOn: Fmt.apiDate(j['paidOn'] as String),
        pay: Pay.fromJson(j['pay'] as Map<String, dynamic>),
      );
}

/// `GET /me/pay`.
class MyPay {
  const MyPay({this.hourlyRateCents, required this.current, required this.previous, required this.history});

  final int? hourlyRateCents;
  final PayStub current;

  /// Last week: usually the paycheck coming this Friday.
  final PayStub previous;
  final List<PaidWeek> history;

  factory MyPay.fromJson(Map<String, dynamic> j) => MyPay(
        hourlyRateCents: (j['hourlyRateCents'] as num?)?.toInt(),
        current: PayStub.fromJson(j['current'] as Map<String, dynamic>),
        previous: PayStub.fromJson(j['previous'] as Map<String, dynamic>),
        history: [for (final p in (j['history'] as List).cast<Map<String, dynamic>>()) PaidWeek.fromJson(p)],
      );
}

class PayrollLine {
  const PayrollLine({
    required this.employeeId,
    required this.fullName,
    required this.document,
    required this.active,
    required this.pay,
    required this.days,
    required this.missingPunchOuts,
    required this.punchedIn,
  });

  final int employeeId;
  final String fullName;
  final String document;
  final bool active;
  final Pay pay;
  final List<DayMinutes> days;
  final int missingPunchOuts;
  final bool punchedIn;

  /// Worked but cannot be paid yet.
  bool get needsRate => pay.totalMinutes > 0 && pay.hourlyRateCents == null;

  factory PayrollLine.fromJson(Map<String, dynamic> j) => PayrollLine(
        employeeId: (j['employeeId'] as num).toInt(),
        fullName: j['fullName'] as String,
        document: j['document'] as String,
        active: j['active'] as bool,
        pay: Pay.fromJson(j['pay'] as Map<String, dynamic>),
        days: _days(j['days']),
        missingPunchOuts: (j['missingPunchOuts'] as num).toInt(),
        punchedIn: j['punchedIn'] as bool,
      );
}

/// `GET /payroll?date=`: one week for the whole crew.
class Payroll {
  const Payroll({
    required this.periodStart,
    required this.periodEnd,
    required this.paid,
    required this.payDate,
    required this.totalGrossCents,
    required this.totalMinutes,
    required this.lines,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final bool paid;
  final DateTime payDate;
  final int totalGrossCents;
  final int totalMinutes;
  final List<PayrollLine> lines;

  int get missingPunchOuts => lines.fold(0, (n, l) => n + l.missingPunchOuts);
  int get withoutRate => lines.where((l) => l.needsRate).length;
  bool get anyPunchedIn => lines.any((l) => l.punchedIn);

  /// The week is over (by the device calendar; the server checks again).
  bool endedBy(DateTime today) => DateTime(today.year, today.month, today.day).isAfter(periodEnd);

  factory Payroll.fromJson(Map<String, dynamic> j) => Payroll(
        periodStart: Fmt.apiDate(j['periodStart'] as String),
        periodEnd: Fmt.apiDate(j['periodEnd'] as String),
        paid: j['paid'] as bool,
        payDate: Fmt.apiDate(j['payDate'] as String),
        totalGrossCents: (j['totalGrossCents'] as num).toInt(),
        totalMinutes: (j['totalMinutes'] as num).toInt(),
        lines: [for (final l in (j['lines'] as List).cast<Map<String, dynamic>>()) PayrollLine.fromJson(l)],
      );
}
