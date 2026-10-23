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

  test('money in US format', () {
    expect(Fmt.money(0), r'$0.00');
    expect(Fmt.money(101400), r'$1,014.00');
    expect(Fmt.money(123456789), r'$1,234,567.89');
    expect(Fmt.money(-505), r'-$5.05');
    expect(Fmt.rate(2450), r'$24.50/hr');
  });

  test('typed amounts to cents', () {
    expect(Fmt.parseCents('25'), 2500);
    expect(Fmt.parseCents('25.5'), 2550);
    expect(Fmt.parseCents(r'$18.05'), 1805);
    expect(Fmt.parseCents('1,000'), 100000);
    expect(Fmt.parseCents('12.345'), isNull);
    expect(Fmt.parseCents('abc'), isNull);
    expect(Fmt.parseCents('12,34'), isNull);
    expect(Fmt.decimal(1805), '18.05');
  });

  test('worked hours and week ranges', () {
    expect(Fmt.hours(0), '0h');
    expect(Fmt.hours(45), '45m');
    expect(Fmt.hours(2400), '40h');
    expect(Fmt.hours(513), '8h 33m');
    expect(Fmt.dayRange(DateTime(2026, 10, 19), DateTime(2026, 10, 25)), 'Oct 19 – 25');
    expect(Fmt.dayRange(DateTime(2026, 10, 26), DateTime(2026, 11, 1)), 'Oct 26 – Nov 1');
    expect(Fmt.apiDate('2026-03-08'), DateTime(2026, 3, 8));
  });
}
