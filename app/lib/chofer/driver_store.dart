import 'package:core/core.dart';

class DriverCredentials {
  const DriverCredentials(this.veh, this.pin);

  final int veh;
  final String pin;
}

/// Driver settings persisted in drift (app-private storage; the PIN is stored as plain text by decision).
class DriverStore {
  DriverStore(this.db);

  final AppDb db;

  Future<DriverCredentials?> credentials() async {
    final veh = int.tryParse(await db.getString('veh') ?? '');
    final pin = await db.getString('pin');
    return veh == null || pin == null ? null : DriverCredentials(veh, pin);
  }

  Future<void> saveCredentials(DriverCredentials c) async {
    await db.putString('veh', '${c.veh}');
    await db.putString('pin', c.pin);
  }

  Future<void> clearCredentials() async {
    await db.remove('veh');
    await db.remove('pin');
  }

  Future<String?> line() => db.getString('line');

  Future<void> saveLine(String line) => db.putString('line', line);
}
