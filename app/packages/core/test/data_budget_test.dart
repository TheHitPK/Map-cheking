import 'dart:io';

import 'package:core/core.dart';
import 'package:core/proto.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

import 'route_snapper_test.dart' show at;

/// CLAUDE.md: passenger < 50 KB per session.
/// HTTP is measured on the wire against a local server returning realistic bodies;
/// MQTT uses the same size formulas MqttLink uses for its counter.
void main() {
  test('a 15-minute passenger session with 3 vehicles stays well under 50 KB', () async {
    final lines = pb.Lines(lines: [for (var i = 0; i < 40; i++) pb.Line(id: 'linea-$i', name: 'Línea número $i')]);
    final nearby = pb.NearbyList(vehicles: [
      for (var v = 1; v <= 3; v++) pb.Nearby(veh: 100 + v, ts: 1800000000, lat: 10650000, lon: -71612000, spd: 30, hdg: 90, distM: 900),
    ]);
    // A winding 4 km road route: 250 points.
    final route = pb.Route(
      polyline: encodePolyline([for (var i = 0; i < 250; i++) at(i * 16.0, (i % 7) * 12.0)]),
      distM: 4000,
      timeS: 600,
    );

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final res = req.response..headers.contentType = ContentType('application', 'x-protobuf');
      final body = switch (req.uri.path) {
        '/lineas' => lines.writeToBuffer(),
        '/ruta' => route.writeToBuffer(),
        '/auth/pasajero' => pb.Token(jwt: 'x' * 316, exp: 1800003600).writeToBuffer(),
        _ => nearby.writeToBuffer(),
      };
      if (body.length > 1024) {
        res.headers.set(HttpHeaders.contentEncodingHeader, 'gzip'); // backend: gzip only > 1 KB
        res.add(gzip.encode(body));
      } else {
        res.add(body);
      }
      await res.close();
    });
    final api = ApiClient(Uri.parse('http://127.0.0.1:${server.port}'));

    // HTTP: token, lines (first time, no ETag), nearby, route + 3 reroutes, one refresh after background.
    final token = await api.passengerToken();
    await api.lines();
    for (var i = 0; i < 2; i++) {
      await api.nearby('santa-rosa', const GeoPoint(10.64, -71.61));
    }
    for (var i = 0; i < 4; i++) {
      await api.route(101, const GeoPoint(10.64, -71.61));
    }
    api.close();
    await server.close(force: true);

    // MQTT: 2 connections (open + resume), 3 subscriptions each, 3 vehicles publishing every 15 s for 15 min.
    final usage = api.usage;
    const topic = 'v/santa-rosa/101';
    final pos = makePos(veh: 101, tsSec: 1800000000, at: const GeoPoint(10.65, -71.61), speedKmh: 30, headingDeg: 90);
    for (var c = 0; c < 2; c++) {
      usage.mqttTx += MqttLink.connectBytes(clientId: 'pas-0123456789', username: 'u', jwt: token.jwt);
      usage.mqttRx += MqttLink.connAckBytes;
      usage.mqttTx += 3 * MqttLink.subscribeBytes(topic);
    }
    usage.mqttRx += 3 * (15 * 60 ~/ 15) * MqttLink.incomingPublishBytes(topic, pos.writeToBuffer().length);
    usage.mqttTx += 15 * 60 ~/ 120 * 2; // PINGREQ every 120 s

    // ignore: avoid_print
    print('passenger session: $usage');
    expect(usage.totalKb, lessThan(50));
    expect(usage.totalKb, lessThan(25), reason: 'keep a 2x margin for poor-network retries');
  });
}
