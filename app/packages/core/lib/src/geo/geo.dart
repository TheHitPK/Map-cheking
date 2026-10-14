import 'dart:math' as math;

/// WGS84 point in degrees. Named GeoPoint to avoid clashing with map libraries' LatLng.
class GeoPoint {
  const GeoPoint(this.lat, this.lon);

  /// From the protocol's degrees * 1e6 integers.
  GeoPoint.e6(int latE6, int lonE6) : this(latE6 / 1e6, lonE6 / 1e6);

  final double lat;
  final double lon;

  int get latE6 => (lat * 1e6).round();
  int get lonE6 => (lon * 1e6).round();

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);

  @override
  String toString() => 'GeoPoint($lat, $lon)';
}

const double earthRadiusM = 6371000;

/// Haversine distance in metres (same formula as the backend's Geo.distanceMeters).
double distanceMeters(GeoPoint a, GeoPoint b) {
  final p1 = _rad(a.lat), p2 = _rad(b.lat);
  final dp = p2 - p1, dl = _rad(b.lon - a.lon);
  final h = math.sin(dp / 2) * math.sin(dp / 2) + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
  return 2 * earthRadiusM * math.asin(math.sqrt(h));
}

double _rad(double deg) => deg * math.pi / 180;

/// Equirectangular projection around [origin], in metres. Accurate enough at city scale.
class LocalProjection {
  LocalProjection(GeoPoint origin)
      : _lat0 = origin.lat,
        _lon0 = origin.lon,
        _kx = earthRadiusM * math.pi / 180 * math.cos(_rad(origin.lat)),
        _ky = earthRadiusM * math.pi / 180;

  final double _lat0, _lon0, _kx, _ky;

  (double x, double y) toXY(GeoPoint p) => ((p.lon - _lon0) * _kx, (p.lat - _lat0) * _ky);
}
