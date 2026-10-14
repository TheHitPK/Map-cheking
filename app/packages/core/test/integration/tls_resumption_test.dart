// Measures TLS handshake bytes to EMQX through a counting proxy (first connection vs reconnection).
//   TRANSMCBO_IT=1 DEV_CA=../../../certs/ca.crt flutter test test/integration/tls_resumption_test.dart
@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final enabled = Platform.environment['TRANSMCBO_IT'] == '1';
final caPath = Platform.environment['DEV_CA'] ?? '../../../certs/ca.crt';
final brokerPort = int.parse(Platform.environment['MQTT_TLS_PORT'] ?? '8883');

/// Forwards a localhost port to the broker and counts bytes per connection.
class CountingProxy {
  late ServerSocket _server;
  final List<(int up, int down)> connections = [];

  int get port => _server.port;

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((client) async {
      final index = connections.length;
      connections.add((0, 0));
      final upstream = await Socket.connect('127.0.0.1', brokerPort);
      client.listen((d) {
        final (u, w) = connections[index];
        connections[index] = (u + d.length, w);
        upstream.add(d);
      }, onDone: upstream.destroy, onError: (_) => upstream.destroy());
      upstream.listen((d) {
        final (u, w) = connections[index];
        connections[index] = (u, w + d.length);
        client.add(d);
      }, onDone: client.destroy, onError: (_) => client.destroy());
    });
  }

  Future<void> stop() => _server.close();
}

void main() {
  if (!enabled) {
    test('TLS resumption', () {}, skip: 'set TRANSMCBO_IT=1 with EMQX TLS on 8883');
    return;
  }

  test('handshake bytes: first connection vs reconnection with the same SecurityContext', () async {
    final proxy = CountingProxy();
    await proxy.start();
    final ctx = SecurityContext(withTrustedRoots: false)..setTrustedCertificates(caPath);

    for (var i = 0; i < 3; i++) {
      final s = await SecureSocket.connect('127.0.0.1', proxy.port, context: ctx);
      // ignore: avoid_print
      print('connection $i: ${s.selectedProtocol} ${s.peerCertificate?.subject}');
      await s.close();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    await proxy.stop();

    for (final (i, (up, down)) in proxy.connections.indexed) {
      // ignore: avoid_print
      print('connection $i: client->broker $up B, broker->client $down B, total ${up + down} B');
    }
    expect(proxy.connections, hasLength(3));
    // dart:io does not resume sessions: every connection is a full handshake. Keep it small (ECDSA chain).
    for (final (up, down) in proxy.connections) {
      expect(up + down, lessThan(2500));
    }
  });
}
