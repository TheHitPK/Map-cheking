import '../geo/geo.dart';
import 'route_snapper.dart';

/// Exponential moving average of speed with a floor, so a stopped vehicle never yields an infinite ETA.
class SpeedEma {
  SpeedEma({this.alpha = 0.3, this.minKmh = 8});

  final double alpha;
  final double minKmh;
  double? _ema;

  void add(double kmh) {
    final v = kmh < 0 ? 0.0 : kmh;
    _ema = _ema == null ? v : alpha * v + (1 - alpha) * _ema!;
  }

  /// Smoothed speed, never below [minKmh].
  double get kmh {
    final v = _ema ?? 0;
    return v < minKmh ? minKmh : v;
  }
}

/// Flags a reroute after [consecutive] readings farther than [thresholdMeters] from the route.
class DeviationDetector {
  DeviationDetector({this.thresholdMeters = 60, this.consecutive = 2});

  final double thresholdMeters;
  final int consecutive;
  int _count = 0;

  /// Returns true when a new route should be requested.
  bool add(double offRouteMeters) {
    _count = offRouteMeters > thresholdMeters ? _count + 1 : 0;
    return _count >= consecutive;
  }

  void reset() => _count = 0;
}

class EtaUpdate {
  const EtaUpdate({
    required this.remainingMeters,
    required this.etaSeconds,
    required this.minSeconds,
    required this.maxSeconds,
    required this.offRouteMeters,
    required this.needsReroute,
    required this.arrived,
  });

  final double remainingMeters;
  final double etaSeconds;

  /// Shown range: ETA ±25 %.
  final double minSeconds;
  final double maxSeconds;
  final double offRouteMeters;
  final bool needsReroute;
  final bool arrived;
}

/// Phone-side ETA for one vehicle against the route from GET /ruta (vehicle -> passenger).
class EtaEstimator {
  EtaEstimator(List<GeoPoint> route, {this.rangeFraction = 0.25, this.arrivedMeters = 30})
      : _snapper = RouteSnapper(route);

  final RouteSnapper _snapper;
  final SpeedEma _speed = SpeedEma();
  final DeviationDetector _deviation = DeviationDetector();
  final double rangeFraction;
  final double arrivedMeters;
  double? _lastRemaining;
  int? _lastTs;

  /// [tsSec] is the fix time (Pos.ts); [reportedKmh] (Pos.spd) seeds the speed before progress is known.
  EtaUpdate update(GeoPoint vehicle, int tsSec, {double? reportedKmh}) {
    final snap = _snapper.snap(vehicle);
    final reroute = _deviation.add(snap.offRouteMeters);
    final onRoute = snap.offRouteMeters <= _snapper.maxOffRouteMeters;

    // Off route: keep the last on-route estimate until the reroute arrives.
    final remaining = onRoute ? snap.remainingMeters : (_lastRemaining ?? snap.remainingMeters);
    if (onRoute) {
      if (_lastRemaining != null && _lastTs != null && tsSec > _lastTs!) {
        _speed.add((_lastRemaining! - remaining) / (tsSec - _lastTs!) * 3.6);
      } else if (reportedKmh != null) {
        _speed.add(reportedKmh);
      }
      _lastRemaining = remaining;
      _lastTs = tsSec;
    }

    final eta = remaining / (_speed.kmh / 3.6);
    return EtaUpdate(
      remainingMeters: remaining,
      etaSeconds: eta,
      minSeconds: eta * (1 - rangeFraction),
      maxSeconds: eta * (1 + rangeFraction),
      offRouteMeters: snap.offRouteMeters,
      needsReroute: reroute,
      arrived: onRoute && remaining <= arrivedMeters,
    );
  }
}
