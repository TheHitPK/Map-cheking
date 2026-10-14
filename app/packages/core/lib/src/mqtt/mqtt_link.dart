import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_data.dart' as typed;

import '../net/data_usage.dart';

class MqttLinkMessage {
  const MqttLinkMessage(this.topic, this.payload, {required this.retained});

  final String topic;

  /// Empty payload = vehicle went out of service (retained cleared).
  final Uint8List payload;
  final bool retained;
}

/// Thin MQTT 5 wrapper shared by both apps.
///
/// - keepalive 120 s, clean start, the JWT from /auth/* as password;
/// - Topic Alias: the first publish to a topic on a connection carries the topic and an alias,
///   later ones only the alias (mqtt5_client does not do this by itself);
/// - no library auto-reconnect: the JWT may have expired, so the app reconnects with a fresh token.
class MqttLink {
  MqttLink({
    required this.host,
    this.port = 1883,
    required this.clientId,
    this.secure = false,
    DataUsage? usage,
    MqttServerClient Function(String host, String clientId, int port)? clientFactory,
  })  : usage = usage ?? DataUsage(),
        _factory = clientFactory ?? ((h, id, p) => MqttServerClient.withPort(h, id, p));

  final String host;
  final int port;
  final String clientId;
  final bool secure;
  final DataUsage usage;
  final MqttServerClient Function(String, String, int) _factory;

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updates;
  final _messages = StreamController<MqttLinkMessage>.broadcast();
  final _disconnects = StreamController<void>.broadcast();
  final Map<String, int> _aliases = {};
  int _aliasMax = 0;

  Stream<MqttLinkMessage> get messages => _messages.stream;

  /// Fires when the connection drops (network, broker, token expiry). Not fired by [disconnect].
  Stream<void> get disconnects => _disconnects.stream;

  bool get connected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  /// [willTopic]: on an ungraceful drop the broker publishes an empty retained payload there.
  Future<void> connect({required String jwt, String username = 'u', String? willTopic}) async {
    await disconnect();
    final c = _factory(host, clientId, port)
      ..secure = secure
      ..keepAlivePeriod = 120
      ..autoReconnect = false
      ..logging(on: false);
    var msg = MqttConnectMessage().withClientIdentifier(clientId).startClean().authenticateAs(username, jwt);
    if (willTopic != null) {
      msg = msg.withWillTopic(willTopic).withWillPayload(typed.Uint8Buffer()).withWillRetain().withWillQos(MqttQos.atMostOnce);
    }
    c.connectionMessage = msg;
    var userDisconnect = false;
    c.onDisconnected = () {
      if (!userDisconnect && identical(_client, c)) _disconnects.add(null);
    };
    _client = c;
    _disconnectHook = () => userDisconnect = true;

    usage.mqttTx += 14 + clientId.length + username.length + jwt.length + (willTopic == null ? 0 : willTopic.length + 4);
    final status = await c.connect();
    usage.mqttRx += 8;
    if (status?.state != MqttConnectionState.connected) {
      _client = null;
      throw MqttLinkException('connect failed: ${status?.reasonCode}');
    }
    _aliases.clear();
    _aliasMax = status?.connectAckMessage.topicAliasMaximum ?? 0;
    _updates = c.updates?.listen(_onUpdates);
  }

  void Function()? _disconnectHook;

  /// QoS 0. Uses a Topic Alias when the broker allows it.
  void publish(String topic, List<int> payload, {bool retain = false}) {
    final c = _client;
    if (c == null || !connected) throw const MqttLinkException('not connected');
    final data = typed.Uint8Buffer()..addAll(payload);
    final msg = MqttPublishMessage().withQos(MqttQos.atMostOnce).publishData(data);
    msg.setRetain(state: retain);

    var topicBytes = 2 + utf8.encode(topic).length;
    final alias = _aliases[topic];
    if (alias != null) {
      msg.toTopic('');
      msg.withTopicAlias(alias);
      topicBytes = 2 + 3; // empty topic + alias property
    } else if (_aliases.length < _aliasMax) {
      final next = _aliases.length + 1;
      _aliases[topic] = next;
      msg.toTopic(topic);
      msg.withTopicAlias(next);
      topicBytes += 3;
    } else {
      msg.toTopic(topic);
    }
    c.publishUserMessage(msg);
    usage.mqttTx += 2 + 1 + topicBytes + payload.length; // fixed header + properties length + topic + payload
  }

  Future<void> subscribe(String topic) async {
    final c = _client;
    if (c == null || !connected) throw const MqttLinkException('not connected');
    c.subscribe(topic, MqttQos.atMostOnce);
    usage.mqttTx += 8 + topic.length;
    usage.mqttRx += 6;
  }

  void unsubscribe(String topic) {
    final c = _client;
    if (c == null || !connected) return;
    c.unsubscribeStringTopic(topic);
    usage.mqttTx += 7 + topic.length;
    usage.mqttRx += 6;
  }

  Future<void> disconnect() async {
    final c = _client;
    if (c == null) return;
    _disconnectHook?.call();
    await _updates?.cancel();
    _updates = null;
    _client = null;
    if (c.connectionStatus?.state == MqttConnectionState.connected) {
      c.disconnect();
      usage.mqttTx += 2;
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _messages.close();
    await _disconnects.close();
  }

  void _onUpdates(List<MqttReceivedMessage<MqttMessage>> batch) {
    for (final m in batch) {
      final pub = m.payload;
      if (pub is! MqttPublishMessage) continue;
      final bytes = Uint8List.fromList(pub.payload.message?.toList() ?? const []);
      final topic = m.topic ?? pub.variableHeader?.topicName ?? '';
      usage.mqttRx += 2 + 2 + topic.length + 1 + bytes.length;
      _messages.add(MqttLinkMessage(topic, bytes, retained: pub.header?.retain ?? false));
    }
  }
}

class MqttLinkException implements Exception {
  const MqttLinkException(this.message);

  final String message;

  @override
  String toString() => 'MqttLinkException: $message';
}
