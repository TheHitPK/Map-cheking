import '../../../core/models.dart';

class Employee {
  const Employee({
    required this.id,
    required this.document,
    required this.fullName,
    required this.role,
    required this.active,
    this.hourlyRateCents,
  });

  final int id;
  final String document;
  final String fullName;

  /// `WORKER` | `SUPERVISOR`.
  final String role;
  final bool active;

  /// Gross pay per hour in US cents; null while not set.
  final int? hourlyRateCents;

  bool get isWorker => role == 'WORKER';

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: (j['id'] as num).toInt(),
        document: j['document'] as String,
        fullName: j['fullName'] as String,
        role: j['role'] as String,
        active: j['active'] as bool,
        hourlyRateCents: (j['hourlyRateCents'] as num?)?.toInt(),
      );
}

class Shift {
  const Shift({
    required this.employeeId,
    required this.worksiteId,
    required this.start,
    required this.end,
    required this.days,
    required this.graceMinutes,
  });

  final int employeeId;
  final int worksiteId;

  /// "07:00:00".
  final String start;
  final String end;
  final List<String> days;
  final int graceMinutes;

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        employeeId: (j['employeeId'] as num).toInt(),
        worksiteId: (j['worksiteId'] as num).toInt(),
        start: j['start'] as String,
        end: j['end'] as String,
        days: (j['days'] as List).cast<String>(),
        graceMinutes: (j['graceMinutes'] as num).toInt(),
      );
}

/// One worker's day, from `GET /attendance/daily`.
class DailyRow {
  const DailyRow({
    required this.employeeId,
    required this.fullName,
    required this.document,
    required this.worksiteId,
    required this.worksiteName,
    required this.shiftStart,
    required this.shiftEnd,
    required this.state,
    required this.inMark,
    required this.outMark,
    required this.earlyLeave,
    required this.onSite,
    required this.rejectedAttempts,
  });

  final int employeeId;
  final String fullName;
  final String document;
  final int worksiteId;
  final String worksiteName;
  final String shiftStart;
  final String shiftEnd;

  /// `OFF` | `PENDING` | `ABSENT` | `ON_TIME` | `LATE`.
  final String state;
  final Mark? inMark;
  final Mark? outMark;
  final bool earlyLeave;
  final bool onSite;
  final int rejectedAttempts;

  factory DailyRow.fromJson(Map<String, dynamic> j) => DailyRow(
        employeeId: (j['employeeId'] as num).toInt(),
        fullName: j['fullName'] as String,
        document: j['document'] as String,
        worksiteId: (j['worksiteId'] as num).toInt(),
        worksiteName: j['worksiteName'] as String,
        shiftStart: j['shiftStart'] as String,
        shiftEnd: j['shiftEnd'] as String,
        state: j['state'] as String,
        inMark: j['in'] == null ? null : Mark.fromJson(j['in'] as Map<String, dynamic>),
        outMark: j['out'] == null ? null : Mark.fromJson(j['out'] as Map<String, dynamic>),
        earlyLeave: j['earlyLeave'] as bool,
        onSite: j['onSite'] as bool,
        rejectedAttempts: (j['rejectedAttempts'] as num).toInt(),
      );
}

/// One mark in the report, from `GET /attendance/marks`.
class MarkRow {
  const MarkRow({required this.employeeName, required this.employeeDocument, required this.worksiteName, required this.mark});

  final String employeeName;
  final String employeeDocument;
  final String worksiteName;
  final Mark mark;

  factory MarkRow.fromJson(Map<String, dynamic> j) => MarkRow(
        employeeName: j['employeeName'] as String,
        employeeDocument: j['employeeDocument'] as String,
        worksiteName: j['worksiteName'] as String,
        mark: Mark.fromJson(j['mark'] as Map<String, dynamic>),
      );
}
