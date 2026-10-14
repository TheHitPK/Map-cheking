//
//  Generated code. Do not modify.
//  source: api.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// GET /lineas
class Line extends $pb.GeneratedMessage {
  factory Line({
    $core.String? id,
    $core.String? name,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  Line._() : super();
  factory Line.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Line.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Line', package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Line clone() => Line()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Line copyWith(void Function(Line) updates) => super.copyWith((message) => updates(message as Line)) as Line;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Line create() => Line._();
  Line createEmptyInstance() => create();
  static $pb.PbList<Line> createRepeated() => $pb.PbList<Line>();
  @$core.pragma('dart2js:noInline')
  static Line getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Line>(create);
  static Line? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);
}

class Lines extends $pb.GeneratedMessage {
  factory Lines({
    $core.Iterable<Line>? lines,
  }) {
    final $result = create();
    if (lines != null) {
      $result.lines.addAll(lines);
    }
    return $result;
  }
  Lines._() : super();
  factory Lines.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Lines.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Lines', package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'), createEmptyInstance: create)
    ..pc<Line>(1, _omitFieldNames ? '' : 'lines', $pb.PbFieldType.PM, subBuilder: Line.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Lines clone() => Lines()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Lines copyWith(void Function(Lines) updates) => super.copyWith((message) => updates(message as Lines)) as Lines;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Lines create() => Lines._();
  Lines createEmptyInstance() => create();
  static $pb.PbList<Lines> createRepeated() => $pb.PbList<Lines>();
  @$core.pragma('dart2js:noInline')
  static Lines getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Lines>(create);
  static Lines? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Line> get lines => $_getList(0);
}

/// GET /lineas/{id}/cercanos
class Nearby extends $pb.GeneratedMessage {
  factory Nearby({
    $core.int? veh,
    $core.int? ts,
    $core.int? lat,
    $core.int? lon,
    $core.int? spd,
    $core.int? hdg,
    $core.int? distM,
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
    if (distM != null) {
      $result.distM = distM;
    }
    return $result;
  }
  Nearby._() : super();
  factory Nearby.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Nearby.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Nearby', package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'veh', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'ts', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.OS3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'lon', $pb.PbFieldType.OS3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'spd', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'hdg', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'distM', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Nearby clone() => Nearby()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Nearby copyWith(void Function(Nearby) updates) => super.copyWith((message) => updates(message as Nearby)) as Nearby;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Nearby create() => Nearby._();
  Nearby createEmptyInstance() => create();
  static $pb.PbList<Nearby> createRepeated() => $pb.PbList<Nearby>();
  @$core.pragma('dart2js:noInline')
  static Nearby getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Nearby>(create);
  static Nearby? _defaultInstance;

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

  @$pb.TagNumber(7)
  $core.int get distM => $_getIZ(6);
  @$pb.TagNumber(7)
  set distM($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasDistM() => $_has(6);
  @$pb.TagNumber(7)
  void clearDistM() => clearField(7);
}

class NearbyList extends $pb.GeneratedMessage {
  factory NearbyList({
    $core.Iterable<Nearby>? vehicles,
  }) {
    final $result = create();
    if (vehicles != null) {
      $result.vehicles.addAll(vehicles);
    }
    return $result;
  }
  NearbyList._() : super();
  factory NearbyList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NearbyList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NearbyList', package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'), createEmptyInstance: create)
    ..pc<Nearby>(1, _omitFieldNames ? '' : 'vehicles', $pb.PbFieldType.PM, subBuilder: Nearby.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NearbyList clone() => NearbyList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NearbyList copyWith(void Function(NearbyList) updates) => super.copyWith((message) => updates(message as NearbyList)) as NearbyList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NearbyList create() => NearbyList._();
  NearbyList createEmptyInstance() => create();
  static $pb.PbList<NearbyList> createRepeated() => $pb.PbList<NearbyList>();
  @$core.pragma('dart2js:noInline')
  static NearbyList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NearbyList>(create);
  static NearbyList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Nearby> get vehicles => $_getList(0);
}

/// GET /ruta?veh&lat&lon — road route from the vehicle to the passenger
class Route extends $pb.GeneratedMessage {
  factory Route({
    $core.String? polyline,
    $core.int? distM,
    $core.int? timeS,
  }) {
    final $result = create();
    if (polyline != null) {
      $result.polyline = polyline;
    }
    if (distM != null) {
      $result.distM = distM;
    }
    if (timeS != null) {
      $result.timeS = timeS;
    }
    return $result;
  }
  Route._() : super();
  factory Route.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Route.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Route', package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'polyline')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'distM', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'timeS', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Route clone() => Route()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Route copyWith(void Function(Route) updates) => super.copyWith((message) => updates(message as Route)) as Route;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Route create() => Route._();
  Route createEmptyInstance() => create();
  static $pb.PbList<Route> createRepeated() => $pb.PbList<Route>();
  @$core.pragma('dart2js:noInline')
  static Route getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Route>(create);
  static Route? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get polyline => $_getSZ(0);
  @$pb.TagNumber(1)
  set polyline($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPolyline() => $_has(0);
  @$pb.TagNumber(1)
  void clearPolyline() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get distM => $_getIZ(1);
  @$pb.TagNumber(2)
  set distM($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDistM() => $_has(1);
  @$pb.TagNumber(2)
  void clearDistM() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get timeS => $_getIZ(2);
  @$pb.TagNumber(3)
  set timeS($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTimeS() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeS() => clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
