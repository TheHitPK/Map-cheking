import 'package:asistencia/core/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lat = 10.6427, lon = -71.6125;

  test('distance matches known values (same formula as backend)', () {
    expect(distanceMeters(lat, lon, lat, lon), 0);
    expect(distanceMeters(lat, lon, lat + 0.001, lon), closeTo(111.2, 0.5));
    expect(distanceMeters(lat, lon, 10.4806, -66.9036) / 1000, closeTo(515, 10));
  });

  group('checkZone', () {
    ZoneCheck at(double dLat, double accuracy) => checkZone(
        centerLat: lat, centerLon: lon, radiusMeters: 100, lat: lat + dLat, lon: lon, accuracyMeters: accuracy);

    test('inside within radius', () {
      final z = at(0.0005, 10); // ~56 m
      expect(z.state, ZoneState.inside);
      expect(z.distanceMeters, closeTo(55.6, 1));
    });

    test('outside beyond radius', () => expect(at(0.002, 10).state, ZoneState.outside));

    test('imprecise fix is not trusted even when the centre looks close', () => expect(at(0, 80).state, ZoneState.imprecise));

    test('radius edge is inside', () {
      final edge = 100 / 111195.0; // metres → degrees of latitude
      expect(at(edge * 0.999, 5).state, ZoneState.inside);
      expect(at(edge * 1.01, 5).state, ZoneState.outside);
    });
  });

  test('uuidV4 has version and variant bits and is unique', () {
    final ids = List.generate(500, (_) => uuidV4());
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    }
    expect(ids.toSet().length, ids.length);
  });
}
