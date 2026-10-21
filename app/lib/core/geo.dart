import 'dart:math' as math;
import 'dart:typed_data';

const _earthRadiusM = 6371008.8;

double _rad(double deg) => deg * math.pi / 180;

/// Great-circle distance in metres (haversine). Same formula as the backend, so the app's
/// "inside / outside" hint agrees with the server's decision.
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(a)));
}

enum ZoneState { inside, outside, imprecise }

class ZoneCheck {
  const ZoneCheck(this.state, this.distanceMeters);

  final ZoneState state;
  final double distanceMeters;
}

/// Mirrors the server rules: accuracy first, then distance ≤ radius.
ZoneCheck checkZone({
  required double centerLat,
  required double centerLon,
  required int radiusMeters,
  required double lat,
  required double lon,
  required double accuracyMeters,
  double maxAccuracyMeters = 50,
}) {
  final d = distanceMeters(centerLat, centerLon, lat, lon);
  if (accuracyMeters > maxAccuracyMeters) return ZoneCheck(ZoneState.imprecise, d);
  return ZoneCheck(d <= radiusMeters ? ZoneState.inside : ZoneState.outside, d);
}

/// Random (v4) UUID, used as the idempotency key of a mark.
String uuidV4([math.Random? random]) {
  final r = random ?? math.Random.secure();
  final b = Uint8List.fromList(List.generate(16, (_) => r.nextInt(256)));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
