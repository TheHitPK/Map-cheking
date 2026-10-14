import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../proto/pos.pb.dart';

part 'app_db.g.dart';

/// Small settings store: credentials, chosen line, cached /lineas body + ETag.
class KeyValues extends Table {
  TextColumn get key => text()();
  BlobColumn get value => blob()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Driver fixes taken while offline, sent later as PosBatch on v/{line}/{veh}/b.
class PendingFixes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get line => text()();
  IntColumn get veh => integer()();
  IntColumn get ts => integer()();
  IntColumn get lat => integer()();
  IntColumn get lon => integer()();
  IntColumn get spd => integer()();
  IntColumn get hdg => integer()();
}

class QueuedFix {
  const QueuedFix(this.id, this.line, this.pos);

  final int id;
  final String line;
  final Pos pos;
}

@DriftDatabase(tables: [KeyValues, PendingFixes])
class AppDb extends _$AppDb {
  AppDb(super.e);

  /// On-device database, shared by the UI isolate and the foreground-task isolate.
  factory AppDb.open() =>
      AppDb(driftDatabase(name: 'transmcbo', native: const DriftNativeOptions(shareAcrossIsolates: true)));

  @override
  int get schemaVersion => 1;

  Future<Uint8List?> getBytes(String key) async =>
      (await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> putBytes(String key, List<int> value) =>
      into(keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: Uint8List.fromList(value)));

  Future<String?> getString(String key) async {
    final b = await getBytes(key);
    return b == null ? null : utf8.decode(b);
  }

  Future<void> putString(String key, String value) => putBytes(key, utf8.encode(value));

  Future<void> remove(String key) => (delete(keyValues)..where((t) => t.key.equals(key))).go();

  Future<void> enqueue(String line, Pos p) => into(pendingFixes).insert(PendingFixesCompanion.insert(
      line: line, veh: p.veh, ts: p.ts, lat: p.lat, lon: p.lon, spd: p.spd, hdg: p.hdg));

  Future<int> pendingCount() async {
    final c = pendingFixes.id.count();
    return (await (selectOnly(pendingFixes)..addColumns([c])).getSingle()).read(c) ?? 0;
  }

  /// Oldest first.
  Future<List<QueuedFix>> oldestPending(int limit) async {
    final rows = await (select(pendingFixes)
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(limit))
        .get();
    return [
      for (final r in rows)
        QueuedFix(r.id, r.line, Pos(veh: r.veh, ts: r.ts, lat: r.lat, lon: r.lon, spd: r.spd, hdg: r.hdg)),
    ];
  }

  Future<void> deletePending(Iterable<int> ids) => (delete(pendingFixes)..where((t) => t.id.isIn(ids))).go();
}
