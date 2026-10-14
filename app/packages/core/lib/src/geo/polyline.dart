import 'geo.dart';

/// Google encoded polyline, precision 1e5 (what GET /ruta returns).
List<GeoPoint> decodePolyline(String encoded) {
  final out = <GeoPoint>[];
  var i = 0, lat = 0, lon = 0;
  int next() {
    var result = 0, shift = 0, b = 0;
    do {
      b = encoded.codeUnitAt(i++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (i < encoded.length) {
    lat += next();
    lon += next();
    out.add(GeoPoint(lat / 1e5, lon / 1e5));
  }
  return out;
}

String encodePolyline(List<GeoPoint> points) {
  final sb = StringBuffer();
  var prevLat = 0, prevLon = 0;
  void put(int v) {
    var z = v < 0 ? ~(v << 1) : v << 1;
    while (z >= 0x20) {
      sb.writeCharCode((0x20 | (z & 0x1f)) + 63);
      z >>= 5;
    }
    sb.writeCharCode(z + 63);
  }

  for (final p in points) {
    final lat = (p.lat * 1e5).round(), lon = (p.lon * 1e5).round();
    put(lat - prevLat);
    put(lon - prevLon);
    prevLat = lat;
    prevLon = lon;
  }
  return sb.toString();
}
