import 'package:core/core.dart';
import 'package:core/proto.dart' as pb;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'route_snapper_test.dart' show at;

class FakePublisher implements LivePublisher {
  @override
  bool connected = true;
  final sent = <(String, List<int>, bool)>[];

  @override
  void publish(String topic, List<int> payload, {bool retain = false}) {
    if (!connected) throw const MqttLinkException('not connected');
    sent.add((topic, payload, retain));
  }
}

final t0 = DateTime.utc(2026, 10, 14, 12);
DateTime sec(int s) => t0.add(Duration(seconds: s));

void main() {
  group('PublishPolicy', () {
    test('first fix always publishes', () {
      expect(PublishPolicy().shouldPublish(t0, at(0, 0), 0), isTrue);
    });

    test('moving: every 50 m or 15 s, whichever comes first', () {
      final p = PublishPolicy()..markPublished(t0, at(0, 0));
      expect(p.shouldPublish(sec(5), at(30, 0), 25), isFalse);
      expect(p.shouldPublish(sec(6), at(55, 0), 25), isTrue, reason: '50 m');
      expect(p.shouldPublish(sec(15), at(30, 0), 25), isTrue, reason: '15 s');
    });

    test('stopped: heartbeat every 60 s only', () {
      final p = PublishPolicy()..markPublished(t0, at(0, 0));
      expect(p.shouldPublish(sec(20), at(5, 0), 0), isFalse);
      expect(p.stopped, isTrue);
      expect(p.dueByTime(sec(59)), isFalse);
      expect(p.dueByTime(sec(60)), isTrue);
    });

    test('timer asks for a fresh fix after 15 s while moving', () {
      final p = PublishPolicy()..markPublished(t0, at(0, 0));
      p.shouldPublish(sec(5), at(40, 0), 30); // moving, below 50 m
      expect(p.dueByTime(sec(14)), isFalse);
      expect(p.dueByTime(sec(15)), isTrue);
    });
  });

  group('DriverSession', () {
    late AppDb db;
    late FakePublisher pub;
    late DriverSession s;

    setUp(() {
      db = AppDb(NativeDatabase.memory());
      pub = FakePublisher();
      s = DriverSession(veh: 7, line: 'santa-rosa', publisher: pub, db: db, batchSize: 3);
    });

    tearDown(() => db.close());

    DriverFix fix(int s, double north, {double kmh = 30}) => DriverFix(time: sec(s), at: at(north, 0), speedKmh: kmh);

    test('online: retained Pos on the live topic', () async {
      await s.onFix(fix(0, 0));

      expect(pub.sent, hasLength(1));
      final (topic, payload, retain) = pub.sent.single;
      expect(topic, 'v/santa-rosa/7');
      expect(retain, isTrue);
      final pos = pb.Pos.fromBuffer(payload);
      expect(pos.veh, 7);
      expect(pos.ts, t0.millisecondsSinceEpoch ~/ 1000);
      expect(pos.spd, 30);
    });

    test('policy filters fixes', () async {
      await s.onFix(fix(0, 0));
      expect(await s.onFix(fix(5, 20)), isFalse);
      expect(pub.sent, hasLength(1));
    });

    test('offline: queued in drift, flushed as PosBatch on /b in order, then live again', () async {
      pub.connected = false;
      for (var i = 0; i < 7; i++) {
        await s.onFix(fix(i * 15, i * 100.0));
      }
      expect(await s.pendingCount(), 7);
      expect(pub.sent, isEmpty);

      pub.connected = true;
      expect(await s.onConnected(), 7);

      final batches = pub.sent.where((m) => m.$1 == 'v/santa-rosa/7/b').toList();
      expect(batches.map((m) => m.$3), everyElement(isFalse), reason: 'batches are not retained');
      final points = [for (final b in batches) ...decodeBatch(pb.PosBatch.fromBuffer(b.$2))];
      expect(points.map((p) => p.ts), [for (var i = 0; i < 7; i++) sec(i * 15).millisecondsSinceEpoch ~/ 1000]);
      expect(batches, hasLength(3), reason: 'batchSize 3 -> 3 + 3 + 1');
      expect(await s.pendingCount(), 0);

      final live = pub.sent.last;
      expect(live.$1, 'v/santa-rosa/7');
      expect(live.$3, isTrue);
    });

    test('connection lost mid-publish keeps the point', () async {
      await s.onFix(fix(0, 0));
      pub.connected = false;
      await s.onFix(fix(15, 100));
      expect(await s.pendingCount(), 1);
    });

    test('points queued under another line go to that line batch topic', () async {
      pub.connected = false;
      await s.onFix(fix(0, 0));
      final other = DriverSession(veh: 7, line: 'bella-vista', publisher: pub, db: db);
      await other.onFix(fix(30, 500));

      pub.connected = true;
      await other.onConnected();
      expect(pub.sent.map((m) => m.$1).take(2), ['v/santa-rosa/7/b', 'v/bella-vista/7/b']);
    });

    test('going out of service clears the retained position', () async {
      await s.onFix(fix(0, 0));
      s.goOffline();
      final (topic, payload, retain) = pub.sent.last;
      expect(topic, 'v/santa-rosa/7');
      expect(payload, isEmpty);
      expect(retain, isTrue);
    });
  });

  group('AppDb', () {
    test('key/value strings and bytes', () async {
      final db = AppDb(NativeDatabase.memory());
      await db.putString('pin', '4821');
      await db.putString('pin', '1111');
      expect(await db.getString('pin'), '1111');
      expect(await db.getString('missing'), isNull);
      await db.remove('pin');
      expect(await db.getString('pin'), isNull);
      await db.close();
    });
  });
}
