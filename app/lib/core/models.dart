/// API models shared by both apps.
library;

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

double? _double(Object? v) => (v as num?)?.toDouble();

class Worksite {
  const Worksite({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lon,
    required this.radiusMeters,
    required this.active,
  });

  final int id;
  final String name;
  final String address;
  final double lat;
  final double lon;
  final int radiusMeters;
  final bool active;

  factory Worksite.fromJson(Map<String, dynamic> j) => Worksite(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        address: (j['address'] as String?) ?? '',
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        radiusMeters: (j['radiusMeters'] as num).toInt(),
        active: j['active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'address': address, 'lat': lat, 'lon': lon, 'radiusMeters': radiusMeters, 'active': active};
}

class Mark {
  const Mark({
    required this.id,
    required this.clientId,
    required this.type,
    required this.status,
    required this.rejection,
    required this.message,
    required this.recordedAt,
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.deferred,
  });

  final int id;
  final String clientId;

  /// `IN` | `OUT`.
  final String type;

  /// `ON_TIME` | `LATE` | `EARLY_LEAVE` | `UNSCHEDULED` | `REJECTED`.
  final String status;
  final String? rejection;

  /// User-facing rejection reason.
  final String? message;
  final DateTime recordedAt;
  final double? distanceMeters;
  final double accuracyMeters;
  final bool deferred;

  bool get accepted => status != 'REJECTED';
  bool get isIn => type == 'IN';

  factory Mark.fromJson(Map<String, dynamic> j) => Mark(
        id: (j['id'] as num).toInt(),
        clientId: j['clientId'] as String,
        type: j['type'] as String,
        status: j['status'] as String,
        rejection: j['rejection'] as String?,
        message: j['message'] as String?,
        recordedAt: DateTime.parse(j['recordedAt'] as String),
        distanceMeters: _double(j['distanceMeters']),
        accuracyMeters: (j['accuracyMeters'] as num).toDouble(),
        deferred: j['deferred'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'type': type,
        'status': status,
        'rejection': rejection,
        'message': message,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'distanceMeters': distanceMeters,
        'accuracyMeters': accuracyMeters,
        'deferred': deferred,
      };
}

class ShiftInfo {
  const ShiftInfo({required this.start, required this.end, required this.days, required this.graceMinutes});

  /// "07:00:00".
  final String start;
  final String end;

  /// MONDAY…SUNDAY.
  final List<String> days;
  final int graceMinutes;

  factory ShiftInfo.fromJson(Map<String, dynamic> j) => ShiftInfo(
        start: j['start'] as String,
        end: j['end'] as String,
        days: (j['days'] as List).cast<String>(),
        graceMinutes: (j['graceMinutes'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {'start': start, 'end': end, 'days': days, 'graceMinutes': graceMinutes};
}

/// The worker's day, from `GET /me/today`.
class TodayInfo {
  const TodayInfo({
    required this.fullName,
    required this.worksite,
    required this.shift,
    required this.todayStart,
    required this.todayEnd,
    required this.marks,
    required this.next,
  });

  final String fullName;
  final Worksite? worksite;
  final ShiftInfo? shift;

  /// Null when there is no shift today.
  final DateTime? todayStart;
  final DateTime? todayEnd;
  final List<Mark> marks;

  /// `IN` | `OUT`: the mark the worker should make now.
  final String next;

  factory TodayInfo.fromJson(Map<String, dynamic> j) => TodayInfo(
        fullName: j['fullName'] as String,
        worksite: j['worksite'] == null ? null : Worksite.fromJson(j['worksite'] as Map<String, dynamic>),
        shift: j['shift'] == null ? null : ShiftInfo.fromJson(j['shift'] as Map<String, dynamic>),
        todayStart: _date(j['todayStart']),
        todayEnd: _date(j['todayEnd']),
        marks: (j['marks'] as List).map((m) => Mark.fromJson(m as Map<String, dynamic>)).toList(),
        next: j['next'] as String,
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'worksite': worksite?.toJson(),
        'shift': shift?.toJson(),
        'todayStart': todayStart?.toUtc().toIso8601String(),
        'todayEnd': todayEnd?.toUtc().toIso8601String(),
        'marks': marks.map((m) => m.toJson()).toList(),
        'next': next,
      };
}
