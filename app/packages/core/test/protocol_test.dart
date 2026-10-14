import 'package:core/core.dart';
import 'package:core/proto.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final first = pb.Pos(veh: 7, ts: 1000, lat: 10642700, lon: -71612500, spd: 20, hdg: 45);

  test('topics', () {
    expect(liveTopic('santa-rosa', 7), 'v/santa-rosa/7');
    expect(batchTopic('santa-rosa', 7), 'v/santa-rosa/7/b');
  });

  test('makePos converts degrees and halves the heading', () {
    final p = makePos(veh: 7, tsSec: 1000, at: const GeoPoint(10.6427, -71.6125), speedKmh: 31.6, headingDeg: 271);
    expect(p.lat, 10642700);
    expect(p.lon, -71612500);
    expect(p.spd, 32);
    expect(p.hdg, 136);
    expect(p.writeToBuffer().length, lessThanOrEqualTo(20));
  });

  test('batch decodes like the backend PosBatchDecoderTest', () {
    // Same vector as backend/src/test/java/com/transmcbo/ingest/PosBatchDecoderTest.java
    final batch = pb.PosBatch(first: first)
      ..dts.addAll([15, 15])
      ..dlat.addAll([300, -100])
      ..dlon.addAll([-50, 0])
      ..spd.addAll([25, 0])
      ..hdg.addAll([90, 0]);

    final pts = decodeBatch(pb.PosBatch.fromBuffer(batch.writeToBuffer()));
    expect(pts.map((p) => [p.ts, p.lat, p.lon, p.spd, p.hdg]), [
      [1000, 10642700, -71612500, 20, 45],
      [1015, 10643000, -71612550, 25, 90],
      [1030, 10642900, -71612550, 0, 0],
    ]);
  });

  test('encodeBatch round-trips and is much smaller than separate Pos messages', () {
    final pts = [
      for (var i = 0; i < 60; i++)
        pb.Pos(veh: 7, ts: 1000 + i * 15, lat: 10642700 + i * 120, lon: -71612500 - i * 40, spd: 30, hdg: 80),
    ];
    final batch = encodeBatch(pts);
    final back = decodeBatch(pb.PosBatch.fromBuffer(batch.writeToBuffer()));

    expect(back, pts);
    final separate = pts.fold<int>(0, (n, p) => n + p.writeToBuffer().length);
    expect(batch.writeToBuffer().length, lessThan(separate ~/ 2));
  });

  test('rejects empty and malformed batches', () {
    expect(() => encodeBatch([]), throwsArgumentError);
    expect(() => decodeBatch(pb.PosBatch(first: first)..dts.add(1)), throwsFormatException);
  });
}
