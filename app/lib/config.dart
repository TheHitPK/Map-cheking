/// Build-time configuration: --dart-define=API_URL=... --dart-define=MQTT_HOST=...
/// TLS: API_URL=https://...:8443 MQTT_PORT=8883 MQTT_TLS=true (+ DEV_CA=true with the local dev CA).
/// Defaults point to the host machine from the Android emulator.
class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');
  static const mqttHost = String.fromEnvironment('MQTT_HOST', defaultValue: '10.0.2.2');
  static const mqttPort = int.fromEnvironment('MQTT_PORT', defaultValue: 1883);
  static const mqttTls = bool.fromEnvironment('MQTT_TLS');

  /// Trust only the local dev CA (assets/certs/dev-ca.pem from tools/gen-dev-certs.sh). Never in release.
  static const devCa = bool.fromEnvironment('DEV_CA');
}
