/// Approximate bytes on the wire for the session (shown in debug builds).
/// HTTP counts compressed bodies plus headers; MQTT counts packet headers, topic and payload.
class DataUsage {
  int httpRx = 0, httpTx = 0, mqttRx = 0, mqttTx = 0;

  int get totalBytes => httpRx + httpTx + mqttRx + mqttTx;
  double get totalKb => totalBytes / 1024;

  void reset() => httpRx = httpTx = mqttRx = mqttTx = 0;

  @override
  String toString() => '${totalKb.toStringAsFixed(1)} KB (http ↓$httpRx ↑$httpTx, mqtt ↓$mqttRx ↑$mqttTx)';
}
