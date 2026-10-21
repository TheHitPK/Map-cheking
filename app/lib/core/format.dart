/// US formatting without extra dependencies: 12-hour clock, "Mon, Oct 19", feet and miles.
/// Distances are stored in metres everywhere else; convert only for display and input.
abstract final class Fmt {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const dayShort = _weekdays;
  static const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const dayKeys = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

  static const feetPerMeter = 3.28084;

  static String two(int n) => n.toString().padLeft(2, '0');

  static String _clock(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:${two(minute)} ${hour < 12 ? 'AM' : 'PM'}';
  }

  /// 7:05 AM (device local time).
  static String time(DateTime t) {
    final l = t.toLocal();
    return _clock(l.hour, l.minute);
  }

  /// "Mon, Oct 19".
  static String day(DateTime d) => '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

  /// ISO date for the API: 2026-10-19.
  static String isoDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  /// "7:00 AM" from the API's "07:00:00".
  static String apiTime(String hhmmss) => _clock(int.parse(hhmmss.substring(0, 2)), int.parse(hhmmss.substring(3, 5)));

  static int metersToFeet(num meters) => (meters * feetPerMeter).round();

  static int feetToMeters(num feet) => (feet / feetPerMeter).round();

  /// "180 ft" below 1,000 ft, "0.4 mi" above.
  static String distance(double meters) {
    final ft = meters * feetPerMeter;
    return ft < 1000 ? '${ft.round()} ft' : '${(ft / 5280).toStringAsFixed(1)} mi';
  }

  /// "Mon–Fri" / "Every day" / "Mon, Wed, Fri" from API day keys.
  static String days(List<String> keys) {
    final idx = keys.map(dayKeys.indexOf).where((i) => i >= 0).toList()..sort();
    if (idx.length == 7) return 'Every day';
    if (idx.length == 5 && idx.last == 4) return 'Mon–Fri';
    if (idx.length == 6 && idx.last == 5) return 'Mon–Sat';
    return idx.map((i) => dayShort[i]).join(', ');
  }
}
