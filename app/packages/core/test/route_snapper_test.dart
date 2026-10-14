import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const lat0 = 10.6427, lon0 = -71.6125; // downtown Maracaibo
const mPerDegLat = 111195.0;

/// Point [north] / [east] metres from the origin.
GeoPoint at(double north, double east) => GeoPoint(
      lat0 + north / mPerDegLat,
      lon0 + east / (mPerDegLat * 0.98281), // cos(10.6427°)
    );

/// Straight route 1 km north, a point every 100 m.
final straight = [for (var m = 0; m <= 1000; m += 100) at(m.toDouble(), 0)];

void main() {
  group('RouteSnapper', () {
    test('projects onto the route and measures remaining distance', () {
      final s = RouteSnapper(straight);
      final r = s.snap(at(250, 5));

      expect(s.totalMeters, closeTo(1000, 1));
      expect(r.segment, 2);
      expect(r.t, closeTo(0.5, 0.01));
      expect(r.offRouteMeters, closeTo(5, 0.5));
      expect(r.alongMeters, closeTo(250, 1));
      expect(r.remainingMeters, closeTo(750, 1));
    });

    test('searches forward from the last matched segment, never backwards', () {
      final s = RouteSnapper(straight);
      s.snap(at(550, 0));
      expect(s.lastSegment, 5);

      final back = s.snap(at(220, 0)); // GPS glitch behind the vehicle
      expect(back.segment, 5);
      expect(back.t, 0);
      expect(s.lastSegment, 5);
    });

    test('a nearby return leg beyond the look-ahead window is ignored', () {
      // U-turn: 400 m north, 30 m east, 400 m back south.
      final u = [at(0, 0), at(200, 0), at(400, 0), at(400, 30), at(200, 30), at(0, 30)];
      final s = RouteSnapper(u, lookAheadMeters: 300);

      // 18 m east of the outbound leg = 12 m from the return leg, but the return leg starts 430 m ahead.
      final r = s.snap(at(50, 18));
      expect(r.segment, 0);
      expect(r.offRouteMeters, closeTo(18, 0.5));
    });

    test('off-route fixes do not advance the matched segment', () {
      final s = RouteSnapper(straight);
      s.snap(at(150, 0));
      final far = s.snap(at(700, 100));

      expect(far.offRouteMeters, greaterThan(60));
      expect(s.lastSegment, 1);
    });
  });

  group('polyline', () {
    test('matches Google reference and the backend encoder', () {
      final pts = [const GeoPoint(38.5, -120.2), const GeoPoint(40.7, -120.95), const GeoPoint(43.252, -126.453)];
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

      expect(encodePolyline(pts), encoded);
      final back = decodePolyline(encoded);
      for (var i = 0; i < pts.length; i++) {
        expect(back[i].lat, closeTo(pts[i].lat, 1e-5));
        expect(back[i].lon, closeTo(pts[i].lon, 1e-5));
      }
    });
  });
}
