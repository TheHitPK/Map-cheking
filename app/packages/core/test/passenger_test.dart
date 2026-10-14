import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/proto.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

import 'route_snapper_test.dart' show at;

const line = 'santa-rosa';
final user = at(0, 0);

/// Vehicles north of the passenger; routes are straight lines south to the passenger.
class FakeApi implements PassengerApi {
  List<pb.Nearby> nearbyResult = [];
  final routeCalls = <int>[];
  final Set<int> notLive = {};
  int nearbyCalls = 0;

  @override
  Future<List<pb.Nearby>> nearby(String line, GeoPoint user) async {
    nearbyCalls++;
    return nearbyResult;
  }

  @override
  Future<pb.Route?> route(int veh, GeoPoint u) async {
    routeCalls.add(veh);
    if (notLive.contains(veh)) return null;
    final from = nearbyResult.firstWhere((n) => n.veh == veh);
    final start = GeoPoint.e6(from.lat, from.lon);
    return pb.Route(polyline: encodePolyline([start, u]), distM: distanceMeters(start, u).round());
  }
}

class FakeFeed implements LiveFeed {
  final _c = StreamController<MqttLinkMessage>.broadcast(sync: true);
  final subscribed = <String>{};

  @override
  Stream<MqttLinkMessage> get messages => _c.stream;

  @override
  Future<void> subscribe(String topic) async => subscribed.add(topic);

  @override
  void unsubscribe(String topic) => subscribed.remove(topic);

  void pos(int veh, int ts, GeoPoint p, {int kmh = 36}) => _c.add(MqttLinkMessage(
      liveTopic(line, veh), makePos(veh: veh, tsSec: ts, at: p, speedKmh: kmh.toDouble(), headingDeg: 180).writeToBuffer(),
      retained: false));

  void outOfService(int veh) => _c.add(MqttLinkMessage(liveTopic(line, veh), Uint8List(0), retained: true));
}

pb.Nearby nearby(int veh, double north, {double east = 0}) {
  final p = at(north, east);
  return pb.Nearby(veh: veh, lat: p.latE6, lon: p.lonE6, spd: 36, ts: 1000, distM: north.round());
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeApi api;
  late FakeFeed feed;
  late DateTime now;
  late PassengerSession s;

  setUp(() {
    api = FakeApi()..nearbyResult = [nearby(1, 800), nearby(2, 1500), nearby(3, 2200), nearby(4, 2900)];
    feed = FakeFeed();
    now = DateTime.utc(2026, 10, 14, 12);
    s = PassengerSession(api: api, feed: feed, line: line, user: user, clock: () => now);
  });

  tearDown(() => s.close());

  test('subscribes to at most 3 vehicles and routes only the closest', () async {
    await s.start();

    expect(feed.subscribed, {'v/$line/1', 'v/$line/2', 'v/$line/3'});
    expect(api.routeCalls, [1]);
    expect(s.view.status, PassengerStatus.tracking);
    expect(s.view.targetVeh, 1);
    expect(s.view.vehicles.map((v) => v.veh), [1, 2, 3]);
    expect(s.view.eta!.remainingMeters, closeTo(800, 5));
  });

  test('live positions move the vehicle and update the ETA', () async {
    await s.start();
    feed.pos(1, 1010, at(700, 0));
    feed.pos(1, 1020, at(600, 0));

    expect(s.view.vehicles.first.at.lat, closeTo(at(600, 0).lat, 1e-6));
    final eta = s.view.eta!;
    expect(eta.remainingMeters, closeTo(600, 5));
    expect(eta.etaSeconds, closeTo(60, 6)); // 10 m/s
    expect(eta.minSeconds, closeTo(eta.etaSeconds * 0.75, 1e-9));
  });

  test('old or repeated timestamps are ignored', () async {
    await s.start();
    feed.pos(1, 1020, at(600, 0));
    feed.pos(1, 1010, at(900, 0));
    expect(s.view.eta!.remainingMeters, closeTo(600, 5));
  });

  test('target goes out of service: unsubscribed and the next vehicle becomes the target', () async {
    await s.start();
    api.nearbyResult = [nearby(2, 1500), nearby(3, 2200)];
    feed.outOfService(1);
    await settle();
    await settle();

    expect(feed.subscribed, isNot(contains('v/$line/1')));
    expect(api.nearbyCalls, 2);
    expect(s.view.targetVeh, 2);
    expect(api.routeCalls, [1, 2]);
  });

  test('deviation twice -> new route, at most once per 30 s', () async {
    await s.start();
    feed.pos(1, 1010, at(700, 100));
    feed.pos(1, 1020, at(650, 110));
    await settle();
    expect(api.routeCalls, [1], reason: 'first route was just fetched: rate limited');

    now = now.add(const Duration(seconds: 31));
    feed.pos(1, 1030, at(600, 120));
    await settle();
    expect(api.routeCalls, [1, 1]);
  });

  test('vehicle that passed the passenger is replaced by the next approaching one', () async {
    await s.start();
    feed.pos(1, 1010, at(10, 0));
    expect(s.view.eta!.arrived, isTrue);

    api.nearbyResult = [nearby(2, 1500), nearby(3, 2200)];
    feed.pos(1, 1020, at(-100, 80));
    feed.pos(1, 1030, at(-200, 90));
    await settle();
    await settle();

    expect(api.nearbyCalls, 2);
    expect(s.view.targetVeh, 2);
  });

  test('no vehicles nearby', () async {
    api.nearbyResult = [];
    await s.start();
    expect(s.view.status, PassengerStatus.noVehicles);
    expect(feed.subscribed, isEmpty);
  });

  test('vehicle no longer live at /ruta time -> refresh', () async {
    api.notLive.add(1);
    await s.start();
    await settle();
    expect(api.nearbyCalls, greaterThanOrEqualTo(2));
  });

  test('stop (background) unsubscribes everything', () async {
    await s.start();
    await s.stop();
    expect(feed.subscribed, isEmpty);
  });
}
