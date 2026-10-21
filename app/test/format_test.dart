import 'package:asistencia/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('12-hour clock from API times', () {
    expect(Fmt.apiTime('00:05:00'), '12:05 AM');
    expect(Fmt.apiTime('07:00:00'), '7:00 AM');
    expect(Fmt.apiTime('12:30:00'), '12:30 PM');
    expect(Fmt.apiTime('22:00:00'), '10:00 PM');
  });

  test('US short dates', () => expect(Fmt.day(DateTime(2026, 10, 19)), 'Mon, Oct 19'));

  test('distances in feet, then miles', () {
    expect(Fmt.distance(30.48), '100 ft');
    expect(Fmt.distance(304), '997 ft');
    expect(Fmt.distance(1609.34), '1.0 mi');
  });

  test('feet/metres round-trip stays within backend bounds', () {
    expect(Fmt.feetToMeters(70), 21);
    expect(Fmt.feetToMeters(6500), 1981);
    expect(Fmt.metersToFeet(100), 328);
  });

  test('work day summaries', () {
    expect(Fmt.days(Fmt.dayKeys), 'Every day');
    expect(Fmt.days(Fmt.dayKeys.take(5).toList()), 'Mon–Fri');
    expect(Fmt.days(Fmt.dayKeys.take(6).toList()), 'Mon–Sat');
    expect(Fmt.days(['FRIDAY', 'MONDAY', 'WEDNESDAY']), 'Mon, Wed, Fri');
  });
}
