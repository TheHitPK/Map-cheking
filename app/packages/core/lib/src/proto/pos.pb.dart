// This is a generated file - do not edit.
//
// Generated from pos.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Live position published by the driver on topic v/{line}/{veh}. ~14 B on the wire.
class Pos extends $pb.GeneratedMessage {
  factory Pos({
    $core.int? veh,
    $core.int? ts,
    $core.int? lat,
    $core.int? lon,
    $core.int? spd,
    $core.int? hdg,
  }) {
    final result = Pos._();
    if (veh != null) result.veh = veh;
    if (ts != null) result.ts = ts;
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (spd != null) result.spd = spd;
    if (hdg != null) result.hdg = hdg;
    return result;
  }

  Pos._();

  factory Pos.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Pos()..mergeFromBuffer(data, registry);
  factory Pos.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Pos()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Pos',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'),
      createEmptyInstance: Pos.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'veh', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'ts', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'lat', fieldType: $pb.PbFieldType.OS3)
    ..aI(4, _omitFieldNames ? '' : 'lon', fieldType: $pb.PbFieldType.OS3)
    ..aI(5, _omitFieldNames ? '' : 'spd', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'hdg', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pos clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pos copyWith(void Function(Pos) updates) =>
      super.copyWith((message) => updates(message as Pos)) as Pos;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Pos() / Pos.new instead')
  static Pos create() => Pos._();
  static $pb.GeneratedMessage $_createMessage() => Pos._();
  @$core.override
  Pos createEmptyInstance() => Pos._();
  @$core.pragma('dart2js:noInline')
  static Pos getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Pos>(Pos.$_createMessage);
  static Pos? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get veh => $_getIZ(0);
  @$pb.TagNumber(1)
  set veh($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVeh() => $_has(0);
  @$pb.TagNumber(1)
  void clearVeh() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get ts => $_getIZ(1);
  @$pb.TagNumber(2)
  set ts($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get lat => $_getIZ(2);
  @$pb.TagNumber(3)
  set lat($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLat() => $_has(2);
  @$pb.TagNumber(3)
  void clearLat() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get lon => $_getIZ(3);
  @$pb.TagNumber(4)
  set lon($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLon() => $_has(3);
  @$pb.TagNumber(4)
  void clearLon() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get spd => $_getIZ(4);
  @$pb.TagNumber(5)
  set spd($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSpd() => $_has(4);
  @$pb.TagNumber(5)
  void clearSpd() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get hdg => $_getIZ(5);
  @$pb.TagNumber(6)
  set hdg($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHdg() => $_has(5);
  @$pb.TagNumber(6)
  void clearHdg() => $_clearField(6);
}

/// Points buffered while offline. `first` is absolute; point i (i >= 1) is
/// point i-1 plus the deltas at index i-1. All repeated fields have equal length.
class PosBatch extends $pb.GeneratedMessage {
  factory PosBatch({
    Pos? first,
    $core.Iterable<$core.int>? dts,
    $core.Iterable<$core.int>? dlat,
    $core.Iterable<$core.int>? dlon,
    $core.Iterable<$core.int>? spd,
    $core.Iterable<$core.int>? hdg,
  }) {
    final result = PosBatch._();
    if (first != null) result.first = first;
    if (dts != null) result.dts.addAll(dts);
    if (dlat != null) result.dlat.addAll(dlat);
    if (dlon != null) result.dlon.addAll(dlon);
    if (spd != null) result.spd.addAll(spd);
    if (hdg != null) result.hdg.addAll(hdg);
    return result;
  }

  PosBatch._();

  factory PosBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PosBatch()..mergeFromBuffer(data, registry);
  factory PosBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PosBatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PosBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'),
      createEmptyInstance: PosBatch.$_createMessage)
    ..aOM<Pos>(1, _omitFieldNames ? '' : 'first',
        subBuilder: Pos.$_createMessage)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'dts', $pb.PbFieldType.KS3)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'dlat', $pb.PbFieldType.KS3)
    ..p<$core.int>(4, _omitFieldNames ? '' : 'dlon', $pb.PbFieldType.KS3)
    ..p<$core.int>(5, _omitFieldNames ? '' : 'spd', $pb.PbFieldType.KU3)
    ..p<$core.int>(6, _omitFieldNames ? '' : 'hdg', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PosBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PosBatch copyWith(void Function(PosBatch) updates) =>
      super.copyWith((message) => updates(message as PosBatch)) as PosBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PosBatch() / PosBatch.new instead')
  static PosBatch create() => PosBatch._();
  static $pb.GeneratedMessage $_createMessage() => PosBatch._();
  @$core.override
  PosBatch createEmptyInstance() => PosBatch._();
  @$core.pragma('dart2js:noInline')
  static PosBatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PosBatch>(PosBatch.$_createMessage);
  static PosBatch? _defaultInstance;

  @$pb.TagNumber(1)
  Pos get first => $_getN(0);
  @$pb.TagNumber(1)
  set first(Pos value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFirst() => $_has(0);
  @$pb.TagNumber(1)
  void clearFirst() => $_clearField(1);
  @$pb.TagNumber(1)
  Pos ensureFirst() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.int> get dts => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.int> get dlat => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.int> get dlon => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.int> get spd => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.int> get hdg => $_getList(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
