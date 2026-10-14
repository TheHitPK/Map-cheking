import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'route_snapper_test.dart' show at, straight;

void main() {
  group('SpeedEma', () {
    test('alpha 0.3', () {
      final ema = SpeedEma()
        ..add(30)
        ..add(40);
      expect(ema.kmh, closeTo(0.3 * 40 + 0.7 * 30, 1e-9)); // 33
    });

    test('never below 8 km/h, also before any sample', () {
      final ema = SpeedEma();
      expect(ema.kmh, 8);
      ema.add(2);
      expect(ema.kmh, 8);
      ema.add(-5); // negative progress is treated as stopped
      expect(ema.kmh, 8);
    });
  });

  group('DeviationDetector', () {
    test('needs two consecutive readings beyond 60 m', () {
      final d = DeviationDetector();
      expect(d.add(80), isFalse);
      expect(d.add(20), isFalse); // back on route resets
      expect(d.add(61), isFalse);
      expect(d.add(90), isTrue);
    });
  });

  group('EtaEstimator', () {
    test('ETA from progress along the route at 36 km/h, shown as ±25 %', () {
      final eta = EtaEstimator(straight);
      late EtaUpdate u;
      for (var i = 0; i <= 5; i++) {
        u = eta.update(at(i * 100.0, 3), 1000 + i * 10); // 100 m every 10 s = 36 km/h
      }

      expect(u.remainingMeters, closeTo(500, 1));
      expect(u.etaSeconds, closeTo(50, 1));
      expect(u.minSeconds, closeTo(u.etaSeconds * 0.75, 1e-9));
      expect(u.maxSeconds, closeTo(u.etaSeconds * 1.25, 1e-9));
      expect(u.needsReroute, isFalse);
      expect(u.arrived, isFalse);
    });

    test('first fix uses the reported speed', () {
      final u = EtaEstimator(straight).update(at(0, 0), 1000, reportedKmh: 36);
      expect(u.etaSeconds, closeTo(100, 1)); // 1000 m at 10 m/s
    });

    test('stopped vehicle falls back to the 8 km/h floor', () {
      final eta = EtaEstimator(straight);
      late EtaUpdate u;
      for (var i = 0; i < 20; i++) {
        u = eta.update(at(500, 0), 1000 + i * 15);
      }
      expect(u.etaSeconds, closeTo(500 / (8 / 3.6), 1)); // 225 s
    });

    test('two readings off route request a new route and keep the last estimate', () {
      final eta = EtaEstimator(straight);
      eta.update(at(200, 0), 1000);
      final first = eta.update(at(300, 80), 1010);
      final second = eta.update(at(320, 90), 1020);

      expect(first.needsReroute, isFalse);
      expect(second.needsReroute, isTrue);
      expect(second.remainingMeters, closeTo(800, 1));
    });

    test('arrived within 30 m of the passenger', () {
      final u = EtaEstimator(straight).update(at(980, 0), 1000);
      expect(u.arrived, isTrue);
    });
  });
}
