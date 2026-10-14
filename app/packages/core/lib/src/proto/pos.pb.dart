//
//  Generated code. Do not modify.
//  source: pos.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

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
    final $result = create();
    if (veh != null) {
      $result.veh = veh;
    }
    if (ts != null) {
      $result.ts = ts;
    }
    if (lat != null) {
      $result.lat = lat;
    }
    if (lon != null) {
      $result.lon = lon;
    }
    if (spd != null) {
      $result.spd = spd;
    }
    if (hdg != null) {
      $result.hdg = hdg;
    }
    return $result;
  }
  Pos._() : super();
  factory Pos.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Pos.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Pos', package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'veh', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'ts', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.OS3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'lon', $pb.PbFieldType.OS3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'spd', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'hdg', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Pos clone() => Pos()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Pos copyWith(void Function(Pos) updates) => super.copyWith((message) => updates(message as Pos)) as Pos;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Pos create() => Pos._();
  Pos createEmptyInstance() => create();
  static $pb.PbList<Pos> createRepeated() => $pb.PbList<Pos>();
  @$core.pragma('dart2js:noInline')
  static Pos getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Pos>(create);
  static Pos? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get veh => $_getIZ(0);
  @$pb.TagNumber(1)
  set veh($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVeh() => $_has(0);
  @$pb.TagNumber(1)
  void clearVeh() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get ts => $_getIZ(1);
  @$pb.TagNumber(2)
  set ts($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTs() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get lat => $_getIZ(2);
  @$pb.TagNumber(3)
  set lat($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLat() => $_has(2);
  @$pb.TagNumber(3)
  void clearLat() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get lon => $_getIZ(3);
  @$pb.TagNumber(4)
  set lon($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLon() => $_has(3);
  @$pb.TagNumber(4)
  void clearLon() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get spd => $_getIZ(4);
  @$pb.TagNumber(5)
  set spd($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasSpd() => $_has(4);
  @$pb.TagNumber(5)
  void clearSpd() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get hdg => $_getIZ(5);
  @$pb.TagNumber(6)
  set hdg($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasHdg() => $_has(5);
  @$pb.TagNumber(6)
  void clearHdg() => clearField(6);
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
    final $result = create();
    if (first != null) {
      $result.first = first;
    }
    if (dts != null) {
      $result.dts.addAll(dts);
    }
    if (dlat != null) {
      $result.dlat.addAll(dlat);
    }
    if (dlon != null) {
      $result.dlon.addAll(dlon);
    }
    if (spd != null) {
      $result.spd.addAll(spd);
    }
    if (hdg != null) {
      $result.hdg.addAll(hdg);
    }
    return $result;
  }
  PosBatch._() : super();
  factory PosBatch.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PosBatch.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PosBatch', package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'), createEmptyInstance: create)
    ..aOM<Pos>(1, _omitFieldNames ? '' : 'first', subBuilder: Pos.create)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'dts', $pb.PbFieldType.KS3)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'dlat', $pb.PbFieldType.KS3)
    ..p<$core.int>(4, _omitFieldNames ? '' : 'dlon', $pb.PbFieldType.KS3)
    ..p<$core.int>(5, _omitFieldNames ? '' : 'spd', $pb.PbFieldType.KU3)
    ..p<$core.int>(6, _omitFieldNames ? '' : 'hdg', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PosBatch clone() => PosBatch()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PosBatch copyWith(void Function(PosBatch) updates) => super.copyWith((message) => updates(message as PosBatch)) as PosBatch;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PosBatch create() => PosBatch._();
  PosBatch createEmptyInstance() => create();
  static $pb.PbList<PosBatch> createRepeated() => $pb.PbList<PosBatch>();
  @$core.pragma('dart2js:noInline')
  static PosBatch getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PosBatch>(create);
  static PosBatch? _defaultInstance;

  @$pb.TagNumber(1)
  Pos get first => $_getN(0);
  @$pb.TagNumber(1)
  set first(Pos v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFirst() => $_has(0);
  @$pb.TagNumber(1)
  void clearFirst() => clearField(1);
  @$pb.TagNumber(1)
  Pos ensureFirst() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get dts => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get dlat => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.int> get dlon => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$core.int> get spd => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<$core.int> get hdg => $_getList(5);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
