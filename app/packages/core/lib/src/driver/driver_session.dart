import 'dart:typed_data';

import '../db/app_db.dart';
import '../geo/geo.dart';
import '../protocol/protocol.dart';
import 'publish_policy.dart';

/// What [DriverSession] needs from the MQTT connection; [MqttLink] implements it.
abstract interface class LivePublisher {
  bool get connected;
  void publish(String topic, List<int> payload, {bool retain});
}

class DriverFix {
  const DriverFix({required this.time, required this.at, this.speedKmh = 0, this.headingDeg = 0});

  final DateTime time;
  final GeoPoint at;
  final double speedKmh;
  final double headingDeg;
}

/// Driver-side protocol logic, independent of GPS and service plumbing:
/// publish policy, retained live position, offline queue in drift and PosBatch flush on reconnect.
class DriverSession {
  DriverSession({
    required this.veh,
    required this.line,
    required this.publisher,
    required this.db,
    PublishPolicy? policy,
    this.batchSize = 500,
  }) : policy = policy ?? PublishPolicy();

  final int veh;
  final String line;
  final LivePublisher publisher;
  final AppDb db;
  final PublishPolicy policy;
  final int batchSize;

  DriverFix? _lastFix;
  bool _flushing = false;
  int publishedLive = 0;

  String get _live => liveTopic(line, veh);

  DriverFix? get lastFix => _lastFix;

  /// Every GPS fix goes through here. Returns true if it was published or queued.
  Future<bool> onFix(DriverFix fix, {bool force = false}) async {
    _lastFix = fix;
    if (!force && !policy.shouldPublish(fix.time, fix.at, fix.speedKmh)) return false;
    final pos = makePos(
      veh: veh,
      tsSec: fix.time.millisecondsSinceEpoch ~/ 1000,
      at: fix.at,
      speedKmh: fix.speedKmh,
      headingDeg: fix.headingDeg,
    );
    policy.markPublished(fix.time, fix.at);
    if (publisher.connected && !_flushing) {
      try {
        publisher.publish(_live, pos.writeToBuffer(), retain: true);
        publishedLive++;
        return true;
      } catch (_) {
        // Connection dropped between the check and the publish: keep the point.
      }
    }
    await db.enqueue(line, pos);
    return true;
  }

  /// After (re)connecting: send queued points as PosBatch on /b, oldest first, then the latest fix live.
  /// Points of a previous line (driver changed line while offline) go to that line's batch topic.
  Future<int> onConnected() async {
    if (_flushing) return 0;
    _flushing = true;
    var sent = 0;
    try {
      while (publisher.connected) {
        final chunk = await db.oldestPending(batchSize);
        if (chunk.isEmpty) break;
        final sameLine = chunk.takeWhile((q) => q.line == chunk.first.line).toList();
        final batch = encodeBatch([for (final q in sameLine) q.pos]);
        publisher.publish(batchTopic(sameLine.first.line, veh), batch.writeToBuffer());
        await db.deletePending(sameLine.map((q) => q.id));
        sent += sameLine.length;
      }
    } finally {
      _flushing = false;
    }
    // Keep the fix's real time: if it is stale the backend drops it instead of showing an old position as new.
    final last = _lastFix;
    if (last != null && publisher.connected) await onFix(last, force: true);
    return sent;
  }

  /// "Fuera de servicio": clears the retained position so passengers stop seeing the vehicle.
  void goOffline() {
    if (publisher.connected) publisher.publish(_live, Uint8List(0), retain: true);
    policy.reset();
  }

  Future<int> pendingCount() => db.pendingCount();
}
