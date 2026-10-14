import '../geo/geo.dart';
import '../proto/pos.pb.dart';

/// Live position, retained: `v/{line}/{veh}`.
String liveTopic(String line, int veh) => 'v/$line/$veh';

/// Positions buffered offline, not retained: `v/{line}/{veh}/b`.
String batchTopic(String line, int veh) => 'v/$line/$veh/b';

/// Builds a [Pos]. Heading is sent as degrees / 2 so it fits a 1-byte varint.
Pos makePos({required int veh, required int tsSec, required GeoPoint at, double speedKmh = 0, double headingDeg = 0}) {
  return Pos(
    veh: veh,
    ts: tsSec,
    lat: at.latE6,
    lon: at.lonE6,
    spd: speedKmh.round().clamp(0, 255),
    hdg: ((headingDeg % 360) / 2).round() % 180,
  );
}

/// First point absolute, the rest as deltas (sint32, zigzag on the wire). Mirrors PosBatchDecoder in the backend.
PosBatch encodeBatch(List<Pos> points) {
  if (points.isEmpty) throw ArgumentError('empty batch');
  final batch = PosBatch(first: points.first);
  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1], p = points[i];
    batch.dts.add(p.ts - prev.ts);
    batch.dlat.add(p.lat - prev.lat);
    batch.dlon.add(p.lon - prev.lon);
    batch.spd.add(p.spd);
    batch.hdg.add(p.hdg);
  }
  return batch;
}

List<Pos> decodeBatch(PosBatch batch) {
  final n = batch.dts.length;
  if (batch.dlat.length != n || batch.dlon.length != n || batch.spd.length != n || batch.hdg.length != n) {
    throw const FormatException('batch arrays differ in length');
  }
  final out = <Pos>[batch.first];
  for (var i = 0; i < n; i++) {
    final prev = out.last;
    out.add(Pos(
      veh: prev.veh,
      ts: prev.ts + batch.dts[i],
      lat: prev.lat + batch.dlat[i],
      lon: prev.lon + batch.dlon[i],
      spd: batch.spd[i],
      hdg: batch.hdg[i],
    ));
  }
  return out;
}
