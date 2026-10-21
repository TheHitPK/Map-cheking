/// Spanish date/time formatting without extra dependencies. Times are shown in the device's local zone.
abstract final class Fmt {
  static const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  static const dayShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const dayKeys = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

  static String two(int n) => n.toString().padLeft(2, '0');

  /// 24 h, e.g. 07:05.
  static String time(DateTime t) {
    final l = t.toLocal();
    return '${two(l.hour)}:${two(l.minute)}';
  }

  /// "lunes 19 oct".
  static String day(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  /// ISO date for the API: 2026-10-19.
  static String isoDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  /// "07:00" from the API's "07:00:00".
  static String hhmm(String apiTime) => apiTime.length >= 5 ? apiTime.substring(0, 5) : apiTime;

  static String distance(double meters) =>
      meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';

  /// "L M X J V" from API day keys.
  static String days(List<String> keys) {
    final idx = keys.map(dayKeys.indexOf).where((i) => i >= 0).toList()..sort();
    if (idx.length == 7) return 'Todos los días';
    if (idx.length == 5 && idx.last == 4) return 'Lunes a viernes';
    if (idx.length == 6 && idx.last == 5) return 'Lunes a sábado';
    return idx.map((i) => dayShort[i]).join(' ');
  }
}
