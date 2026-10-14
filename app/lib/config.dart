/// Build-time configuration: --dart-define=API_URL=... --dart-define=MQTT_HOST=...
/// Defaults point to the host machine from the Android emulator.
class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');
  static const mqttHost = String.fromEnvironment('MQTT_HOST', defaultValue: '10.0.2.2');
  static const mqttPort = int.fromEnvironment('MQTT_PORT', defaultValue: 1883);
  static const mqttTls = bool.fromEnvironment('MQTT_TLS');
}
