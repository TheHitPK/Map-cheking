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

  /// "Oct 19 – 25" in one month, "Oct 26 – Nov 1" across two.
  static String dayRange(DateTime from, DateTime to) => from.month == to.month
      ? '${_months[from.month - 1]} ${from.day} – ${to.day}'
      : '${_months[from.month - 1]} ${from.day} – ${_months[to.month - 1]} ${to.day}';

  /// Date-only value from the API ("2026-10-19"), as a local calendar date.
  static DateTime apiDate(String iso) {
    final p = iso.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  // Money is kept in US cents (int) everywhere; format only for display.

  static String _grouped(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  /// "$1,234.56".
  static String money(int cents) =>
      '${cents < 0 ? '-' : ''}\$${_grouped(cents.abs() ~/ 100)}.${two(cents.abs() % 100)}';

  /// "$25.50/hr".
  static String rate(int cents) => '${money(cents)}/hr';

  /// "25.50" for an input field.
  static String decimal(int cents) => '${cents ~/ 100}.${two(cents % 100)}';

  /// Cents from what a person types: "25", "25.5", "$25.50", "1,000". Null if it isn't a valid amount.
  static int? parseCents(String text) {
    final m = RegExp(r'^\$?\s*(\d{1,3}(?:,\d{3})*|\d+)(?:\.(\d{1,2}))?$').firstMatch(text.trim());
    if (m == null) return null;
    final dollars = int.parse(m[1]!.replaceAll(',', ''));
    final cents = m[2] == null ? 0 : int.parse(m[2]!.padRight(2, '0'));
    return dollars * 100 + cents;
  }

  /// Worked time: "8h 33m", "40h", "45m", "0h".
  static String hours(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    if (h == 0 && m > 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
