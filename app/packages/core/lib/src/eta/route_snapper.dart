import 'dart:math' as math;

import '../geo/geo.dart';

class SnapResult {
  const SnapResult({
    required this.segment,
    required this.t,
    required this.point,
    required this.offRouteMeters,
    required this.alongMeters,
    required this.remainingMeters,
  });

  /// Index of the segment points[segment] -> points[segment + 1].
  final int segment;

  /// Position within the segment, 0..1.
  final double t;
  final GeoPoint point;
  final double offRouteMeters;
  final double alongMeters;
  final double remainingMeters;
}

/// Projects vehicle positions onto a route polyline (vehicle -> passenger).
///
/// Searches forward from the last matched segment, within [lookAheadMeters] of route distance,
/// so a route that loops back near itself does not make the vehicle jump ahead. Positions farther
/// than [maxOffRouteMeters] from the route are reported but do not advance the matched segment.
class RouteSnapper {
  RouteSnapper(List<GeoPoint> points, {this.lookAheadMeters = 1000, this.maxOffRouteMeters = 60})
      : assert(points.length >= 2, 'a route needs at least 2 points'),
        _points = List.unmodifiable(points),
        _cum = _cumulative(points);

  final List<GeoPoint> _points;
  final List<double> _cum;
  final double lookAheadMeters;
  final double maxOffRouteMeters;
  int _last = 0;

  double get totalMeters => _cum.last;
  int get lastSegment => _last;

  static List<double> _cumulative(List<GeoPoint> pts) {
    final cum = List<double>.filled(pts.length, 0);
    for (var i = 1; i < pts.length; i++) {
      cum[i] = cum[i - 1] + distanceMeters(pts[i - 1], pts[i]);
    }
    return cum;
  }

  SnapResult snap(GeoPoint p) {
    SnapResult? best;
    final limit = _cum[_last] + lookAheadMeters;
    for (var i = _last; i < _points.length - 1 && _cum[i] <= limit; i++) {
      final r = _project(i, p);
      if (best == null || r.offRouteMeters < best.offRouteMeters) {
        best = r;
      }
    }
    if (best!.offRouteMeters <= maxOffRouteMeters) {
      _last = best.segment;
    }
    return best;
  }

  SnapResult _project(int i, GeoPoint p) {
    final a = _points[i], b = _points[i + 1];
    final proj = LocalProjection(a);
    final (bx, by) = proj.toXY(b);
    final (px, py) = proj.toXY(p);
    final len2 = bx * bx + by * by;
    final t = len2 == 0 ? 0.0 : ((px * bx + py * by) / len2).clamp(0.0, 1.0);
    final dx = px - t * bx, dy = py - t * by;
    final segLen = _cum[i + 1] - _cum[i];
    final along = _cum[i] + t * segLen;
    return SnapResult(
      segment: i,
      t: t,
      point: GeoPoint(a.lat + (b.lat - a.lat) * t, a.lon + (b.lon - a.lon) * t),
      offRouteMeters: _hypot(dx, dy),
      alongMeters: along,
      remainingMeters: totalMeters - along,
    );
  }

  static double _hypot(double x, double y) => math.sqrt(x * x + y * y);
}
