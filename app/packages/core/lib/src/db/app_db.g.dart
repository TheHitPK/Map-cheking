// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<Uint8List> value = GeneratedColumn<Uint8List>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final Uint8List value;
  const KeyValue({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<Uint8List>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<Uint8List>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<Uint8List>(value),
    };
  }

  KeyValue copyWith({String? key, Uint8List? value}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, $driftBlobEquality.hash(value));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValue &&
          other.key == this.key &&
          $driftBlobEquality.equals(other.value, this.value));
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<Uint8List> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required Uint8List value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
    Expression<String>? key,
    Expression<Uint8List>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<Uint8List>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<Uint8List>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingFixesTable extends PendingFixes
    with TableInfo<$PendingFixesTable, PendingFixe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingFixesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<String> line = GeneratedColumn<String>(
    'line',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehMeta = const VerificationMeta('veh');
  @override
  late final GeneratedColumn<int> veh = GeneratedColumn<int>(
    'veh',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<int> lat = GeneratedColumn<int>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<int> lon = GeneratedColumn<int>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spdMeta = const VerificationMeta('spd');
  @override
  late final GeneratedColumn<int> spd = GeneratedColumn<int>(
    'spd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hdgMeta = const VerificationMeta('hdg');
  @override
  late final GeneratedColumn<int> hdg = GeneratedColumn<int>(
    'hdg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, line, veh, ts, lat, lon, spd, hdg];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_fixes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingFixe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    } else if (isInserting) {
      context.missing(_lineMeta);
    }
    if (data.containsKey('veh')) {
      context.handle(
        _vehMeta,
        veh.isAcceptableOrUnknown(data['veh']!, _vehMeta),
      );
    } else if (isInserting) {
      context.missing(_vehMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('spd')) {
      context.handle(
        _spdMeta,
        spd.isAcceptableOrUnknown(data['spd']!, _spdMeta),
      );
    } else if (isInserting) {
      context.missing(_spdMeta);
    }
    if (data.containsKey('hdg')) {
      context.handle(
        _hdgMeta,
        hdg.isAcceptableOrUnknown(data['hdg']!, _hdgMeta),
      );
    } else if (isInserting) {
      context.missing(_hdgMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingFixe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingFixe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line'],
      )!,
      veh: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}veh'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lon'],
      )!,
      spd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spd'],
      )!,
      hdg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hdg'],
      )!,
    );
  }

  @override
  $PendingFixesTable createAlias(String alias) {
    return $PendingFixesTable(attachedDatabase, alias);
  }
}

class PendingFixe extends DataClass implements Insertable<PendingFixe> {
  final int id;
  final String line;
  final int veh;
  final int ts;
  final int lat;
  final int lon;
  final int spd;
  final int hdg;
  const PendingFixe({
    required this.id,
    required this.line,
    required this.veh,
    required this.ts,
    required this.lat,
    required this.lon,
    required this.spd,
    required this.hdg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['line'] = Variable<String>(line);
    map['veh'] = Variable<int>(veh);
    map['ts'] = Variable<int>(ts);
    map['lat'] = Variable<int>(lat);
    map['lon'] = Variable<int>(lon);
    map['spd'] = Variable<int>(spd);
    map['hdg'] = Variable<int>(hdg);
    return map;
  }

  PendingFixesCompanion toCompanion(bool nullToAbsent) {
    return PendingFixesCompanion(
      id: Value(id),
      line: Value(line),
      veh: Value(veh),
      ts: Value(ts),
      lat: Value(lat),
      lon: Value(lon),
      spd: Value(spd),
      hdg: Value(hdg),
    );
  }

  factory PendingFixe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingFixe(
      id: serializer.fromJson<int>(json['id']),
      line: serializer.fromJson<String>(json['line']),
      veh: serializer.fromJson<int>(json['veh']),
      ts: serializer.fromJson<int>(json['ts']),
      lat: serializer.fromJson<int>(json['lat']),
      lon: serializer.fromJson<int>(json['lon']),
      spd: serializer.fromJson<int>(json['spd']),
      hdg: serializer.fromJson<int>(json['hdg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'line': serializer.toJson<String>(line),
      'veh': serializer.toJson<int>(veh),
      'ts': serializer.toJson<int>(ts),
      'lat': serializer.toJson<int>(lat),
      'lon': serializer.toJson<int>(lon),
      'spd': serializer.toJson<int>(spd),
      'hdg': serializer.toJson<int>(hdg),
    };
  }

  PendingFixe copyWith({
    int? id,
    String? line,
    int? veh,
    int? ts,
    int? lat,
    int? lon,
    int? spd,
    int? hdg,
  }) => PendingFixe(
    id: id ?? this.id,
    line: line ?? this.line,
    veh: veh ?? this.veh,
    ts: ts ?? this.ts,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    spd: spd ?? this.spd,
    hdg: hdg ?? this.hdg,
  );
  PendingFixe copyWithCompanion(PendingFixesCompanion data) {
    return PendingFixe(
      id: data.id.present ? data.id.value : this.id,
      line: data.line.present ? data.line.value : this.line,
      veh: data.veh.present ? data.veh.value : this.veh,
      ts: data.ts.present ? data.ts.value : this.ts,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      spd: data.spd.present ? data.spd.value : this.spd,
      hdg: data.hdg.present ? data.hdg.value : this.hdg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingFixe(')
          ..write('id: $id, ')
          ..write('line: $line, ')
          ..write('veh: $veh, ')
          ..write('ts: $ts, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('spd: $spd, ')
          ..write('hdg: $hdg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, line, veh, ts, lat, lon, spd, hdg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingFixe &&
          other.id == this.id &&
          other.line == this.line &&
          other.veh == this.veh &&
          other.ts == this.ts &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.spd == this.spd &&
          other.hdg == this.hdg);
}

class PendingFixesCompanion extends UpdateCompanion<PendingFixe> {
  final Value<int> id;
  final Value<String> line;
  final Value<int> veh;
  final Value<int> ts;
  final Value<int> lat;
  final Value<int> lon;
  final Value<int> spd;
  final Value<int> hdg;
  const PendingFixesCompanion({
    this.id = const Value.absent(),
    this.line = const Value.absent(),
    this.veh = const Value.absent(),
    this.ts = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.spd = const Value.absent(),
    this.hdg = const Value.absent(),
  });
  PendingFixesCompanion.insert({
    this.id = const Value.absent(),
    required String line,
    required int veh,
    required int ts,
    required int lat,
    required int lon,
    required int spd,
    required int hdg,
  }) : line = Value(line),
       veh = Value(veh),
       ts = Value(ts),
       lat = Value(lat),
       lon = Value(lon),
       spd = Value(spd),
       hdg = Value(hdg);
  static Insertable<PendingFixe> custom({
    Expression<int>? id,
    Expression<String>? line,
    Expression<int>? veh,
    Expression<int>? ts,
    Expression<int>? lat,
    Expression<int>? lon,
    Expression<int>? spd,
    Expression<int>? hdg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (line != null) 'line': line,
      if (veh != null) 'veh': veh,
      if (ts != null) 'ts': ts,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (spd != null) 'spd': spd,
      if (hdg != null) 'hdg': hdg,
    });
  }

  PendingFixesCompanion copyWith({
    Value<int>? id,
    Value<String>? line,
    Value<int>? veh,
    Value<int>? ts,
    Value<int>? lat,
    Value<int>? lon,
    Value<int>? spd,
    Value<int>? hdg,
  }) {
    return PendingFixesCompanion(
      id: id ?? this.id,
      line: line ?? this.line,
      veh: veh ?? this.veh,
      ts: ts ?? this.ts,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      spd: spd ?? this.spd,
      hdg: hdg ?? this.hdg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (line.present) {
      map['line'] = Variable<String>(line.value);
    }
    if (veh.present) {
      map['veh'] = Variable<int>(veh.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (lat.present) {
      map['lat'] = Variable<int>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<int>(lon.value);
    }
    if (spd.present) {
      map['spd'] = Variable<int>(spd.value);
    }
    if (hdg.present) {
      map['hdg'] = Variable<int>(hdg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingFixesCompanion(')
          ..write('id: $id, ')
          ..write('line: $line, ')
          ..write('veh: $veh, ')
          ..write('ts: $ts, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('spd: $spd, ')
          ..write('hdg: $hdg')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $PendingFixesTable pendingFixes = $PendingFixesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [keyValues, pendingFixes];
}

typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required Uint8List value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<Uint8List> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDb, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDb, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDb, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<Uint8List> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDb, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDb db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<Uint8List> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required Uint8List value,
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDb, $KeyValuesTable, KeyValue>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDb, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;
typedef $$PendingFixesTableCreateCompanionBuilder =
    PendingFixesCompanion Function({
      Value<int> id,
      required String line,
      required int veh,
      required int ts,
      required int lat,
      required int lon,
      required int spd,
      required int hdg,
    });
typedef $$PendingFixesTableUpdateCompanionBuilder =
    PendingFixesCompanion Function({
      Value<int> id,
      Value<String> line,
      Value<int> veh,
      Value<int> ts,
      Value<int> lat,
      Value<int> lon,
      Value<int> spd,
      Value<int> hdg,
    });

class $$PendingFixesTableFilterComposer
    extends Composer<_$AppDb, $PendingFixesTable> {
  $$PendingFixesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get veh => $composableBuilder(
    column: $table.veh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spd => $composableBuilder(
    column: $table.spd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hdg => $composableBuilder(
    column: $table.hdg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingFixesTableOrderingComposer
    extends Composer<_$AppDb, $PendingFixesTable> {
  $$PendingFixesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get veh => $composableBuilder(
    column: $table.veh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spd => $composableBuilder(
    column: $table.spd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hdg => $composableBuilder(
    column: $table.hdg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingFixesTableAnnotationComposer
    extends Composer<_$AppDb, $PendingFixesTable> {
  $$PendingFixesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<int> get veh =>
      $composableBuilder(column: $table.veh, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<int> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<int> get spd =>
      $composableBuilder(column: $table.spd, builder: (column) => column);

  GeneratedColumn<int> get hdg =>
      $composableBuilder(column: $table.hdg, builder: (column) => column);
}

class $$PendingFixesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $PendingFixesTable,
          PendingFixe,
          $$PendingFixesTableFilterComposer,
          $$PendingFixesTableOrderingComposer,
          $$PendingFixesTableAnnotationComposer,
          $$PendingFixesTableCreateCompanionBuilder,
          $$PendingFixesTableUpdateCompanionBuilder,
          (
            PendingFixe,
            BaseReferences<_$AppDb, $PendingFixesTable, PendingFixe>,
          ),
          PendingFixe,
          PrefetchHooks Function()
        > {
  $$PendingFixesTableTableManager(_$AppDb db, $PendingFixesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingFixesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingFixesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingFixesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> line = const Value.absent(),
                Value<int> veh = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> lat = const Value.absent(),
                Value<int> lon = const Value.absent(),
                Value<int> spd = const Value.absent(),
                Value<int> hdg = const Value.absent(),
              }) => PendingFixesCompanion(
                id: id,
                line: line,
                veh: veh,
                ts: ts,
                lat: lat,
                lon: lon,
                spd: spd,
                hdg: hdg,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String line,
                required int veh,
                required int ts,
                required int lat,
                required int lon,
                required int spd,
                required int hdg,
              }) => PendingFixesCompanion.insert(
                id: id,
                line: line,
                veh: veh,
                ts: ts,
                lat: lat,
                lon: lon,
                spd: spd,
                hdg: hdg,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingFixesTable, PendingFixe>(table),
                  BaseReferences<_$AppDb, $PendingFixesTable, PendingFixe>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingFixesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $PendingFixesTable,
      PendingFixe,
      $$PendingFixesTableFilterComposer,
      $$PendingFixesTableOrderingComposer,
      $$PendingFixesTableAnnotationComposer,
      $$PendingFixesTableCreateCompanionBuilder,
      $$PendingFixesTableUpdateCompanionBuilder,
      (PendingFixe, BaseReferences<_$AppDb, $PendingFixesTable, PendingFixe>),
      PendingFixe,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$PendingFixesTableTableManager get pendingFixes =>
      $$PendingFixesTableTableManager(_db, _db.pendingFixes);
}
