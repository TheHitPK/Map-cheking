import '../geo/geo.dart';

/// When the driver publishes: every >= 50 m or 15 s, whichever comes first; stopped -> heartbeat every 60 s.
class PublishPolicy {
  PublishPolicy({
    this.minDistanceMeters = 50,
    this.movingInterval = const Duration(seconds: 15),
    this.stoppedInterval = const Duration(seconds: 60),
    this.stoppedKmh = 3,
    this.stoppedMeters = 20,
  });

  final double minDistanceMeters;
  final Duration movingInterval;
  final Duration stoppedInterval;

  /// Below this reported speed and within [stoppedMeters] of the last publish, the vehicle counts as stopped.
  final double stoppedKmh;
  final double stoppedMeters;

  DateTime? _lastAt;
  GeoPoint? _lastPoint;
  bool _stopped = false;

  bool get stopped => _stopped;

  /// A new GPS fix arrived.
  bool shouldPublish(DateTime now, GeoPoint at, double speedKmh) {
    if (_lastAt == null || _lastPoint == null) return true;
    final moved = distanceMeters(_lastPoint!, at);
    _stopped = speedKmh < stoppedKmh && moved < stoppedMeters;
    if (moved >= minDistanceMeters) return true;
    return now.difference(_lastAt!) >= (_stopped ? stoppedInterval : movingInterval);
  }

  /// Timer tick without a new fix (distanceFilter 50 suppresses them when slow or stopped):
  /// true when it is time to read a fresh position and publish.
  bool dueByTime(DateTime now) =>
      _lastAt == null || now.difference(_lastAt!) >= (_stopped ? stoppedInterval : movingInterval);

  void markPublished(DateTime now, GeoPoint at) {
    _lastAt = now;
    _lastPoint = at;
  }

  void reset() {
    _lastAt = null;
    _lastPoint = null;
    _stopped = false;
  }
}
