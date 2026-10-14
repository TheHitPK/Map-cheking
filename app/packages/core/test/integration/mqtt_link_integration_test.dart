// End-to-end against the local stack (docker compose + backend on :8080):
//   TRANSMCBO_IT=1 flutter test test/integration            (plain MQTT 1883)
//   TRANSMCBO_IT=1 MQTT_TLS=1 flutter test test/integration (TLS 8883)
// Needs vehicle 7 with PIN 4821 in the `vehicle` table.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:core/core.dart';
import 'package:core/proto.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

const line = 'santa-rosa';
const veh = 7;
const user = GeoPoint(10.6427, -71.6125);

final enabled = Platform.environment['TRANSMCBO_IT'] == '1';
final apiUrl = Platform.environment['API_URL'] ?? 'http://127.0.0.1:8080';
final mqttHost = Platform.environment['MQTT_HOST'] ?? '127.0.0.1';

/// MQTT_TLS=1: same tests over TLS on 8883, trusting DEV_CA (certs/ca.crt from tools/gen-dev-certs.sh).
final tls = Platform.environment['MQTT_TLS'] == '1';
final tlsContext = tls
    ? (SecurityContext(withTrustedRoots: false)..setTrustedCertificates(Platform.environment['DEV_CA'] ?? '../../../certs/ca.crt'))
    : null;

MqttLink link(String clientId) =>
    MqttLink(host: mqttHost, port: tls ? 8883 : 1883, secure: tls, securityContext: tlsContext, clientId: clientId);

void main() {
  if (!enabled) {
    test('MQTT integration', () {}, skip: 'set TRANSMCBO_IT=1 with the local stack running');
    return;
  }
  late ApiClient api;
  late MqttLink driver;
  final links = <MqttLink>[];

  Future<MqttLink> passenger(String id) async {
    final token = await api.passengerToken();
    final l = link(id);
    await l.connect(jwt: token.jwt);
    links.add(l);
    return l;
  }

  setUp(() async {
    api = ApiClient(Uri.parse(apiUrl));
    final token = await api.driverToken(veh: veh, pin: '4821', line: line);
    driver = link('veh-$veh-it');
    await driver.connect(jwt: token.jwt, username: 'veh:$veh', willTopic: liveTopic(line, veh));
    links.add(driver);
  });

  tearDown(() async {
    for (final l in links) {
      await l.dispose();
    }
    links.clear();
    api.close();
  });

  pb.Pos pos(int i) => makePos(
        veh: veh,
        tsSec: DateTime.now().millisecondsSinceEpoch ~/ 1000 + i,
        at: GeoPoint(user.lat + i * 0.0001, user.lon),
        speedKmh: 20,
        headingDeg: 180,
      );

  test('Topic Alias: later publishes carry no topic and the broker still resolves it', () async {
    final p = await passenger('pas-it-1');
    final got = <MqttLinkMessage>[];
    final sub = p.messages.listen(got.add);
    await p.subscribe(liveTopic(line, veh));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    got.clear(); // drop any retained message from earlier runs

    final sizes = <int>[];
    for (var i = 0; i < 3; i++) {
      final before = driver.usage.mqttTx;
      driver.publish(liveTopic(line, veh), pos(i).writeToBuffer(), retain: true);
      sizes.add(driver.usage.mqttTx - before);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    await sub.cancel();

    expect(got, hasLength(3));
    expect(got.map((m) => m.topic), everyElement(liveTopic(line, veh)));
    expect(got.map((m) => pb.Pos.fromBuffer(m.payload).lat), [for (var i = 0; i < 3; i++) pos(i).lat]);
    expect(sizes[1], lessThan(sizes[0]), reason: 'alias-only publish is smaller');
    expect(sizes[1], lessThanOrEqualTo(30), reason: 'Pos + headers stays tiny');
  });

  test('backend ingests alias publishes: vehicle shows up in /cercanos', () async {
    driver.publish(liveTopic(line, veh), pos(0).writeToBuffer(), retain: true);
    driver.publish(liveTopic(line, veh), pos(1).writeToBuffer(), retain: true);
    await Future<void>.delayed(const Duration(seconds: 3)); // Redis flusher runs every 1 s

    final nearby = await api.nearby(line, user);
    expect(nearby.map((n) => n.veh), contains(veh));
  });

  test('retained position reaches a late subscriber; empty payload clears it', () async {
    driver.publish(liveTopic(line, veh), pos(5).writeToBuffer(), retain: true);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final late1 = await passenger('pas-it-2');
    final first = late1.messages.first.timeout(const Duration(seconds: 5));
    await late1.subscribe(liveTopic(line, veh));
    final m = await first;
    expect(m.retained, isTrue);
    expect(pb.Pos.fromBuffer(m.payload).lat, pos(5).lat);

    driver.publish(liveTopic(line, veh), const [], retain: true); // "Fuera de servicio"
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final late2 = await passenger('pas-it-3');
    final got = <MqttLinkMessage>[];
    final sub = late2.messages.listen(got.add);
    await late2.subscribe(liveTopic(line, veh));
    await Future<void>.delayed(const Duration(seconds: 2));
    await sub.cancel();
    expect(got, isEmpty);
  });

  test('ACL: the passenger cannot publish, the driver cannot impersonate another vehicle', () async {
    final p = await passenger('pas-it-4');
    final watcher = await passenger('pas-it-5');
    final got = <MqttLinkMessage>[];
    final sub = watcher.messages.listen(got.add);
    await watcher.subscribe(liveTopic(line, 8));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    got.clear();

    // QoS 0 denials are silent (or EMQX drops the connection): nothing must reach the subscriber.
    try {
      p.publish(liveTopic(line, 8), pos(0).writeToBuffer());
    } on MqttLinkException catch (_) {}
    try {
      driver.publish(liveTopic(line, 8), pos(0).writeToBuffer());
    } on MqttLinkException catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 2));
    await sub.cancel();
    expect(got, isEmpty);
  });
}
