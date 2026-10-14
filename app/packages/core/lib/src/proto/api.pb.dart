// This is a generated file - do not edit.
//
// Generated from api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// GET /lineas
class Line extends $pb.GeneratedMessage {
  factory Line({
    $core.String? id,
    $core.String? name,
  }) {
    final result = Line._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    return result;
  }

  Line._();

  factory Line.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Line()..mergeFromBuffer(data, registry);
  factory Line.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Line()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Line',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'),
      createEmptyInstance: Line.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Line clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Line copyWith(void Function(Line) updates) =>
      super.copyWith((message) => updates(message as Line)) as Line;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Line() / Line.new instead')
  static Line create() => Line._();
  static $pb.GeneratedMessage $_createMessage() => Line._();
  @$core.override
  Line createEmptyInstance() => Line._();
  @$core.pragma('dart2js:noInline')
  static Line getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Line>(Line.$_createMessage);
  static Line? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class Lines extends $pb.GeneratedMessage {
  factory Lines({
    $core.Iterable<Line>? lines,
  }) {
    final result = Lines._();
    if (lines != null) result.lines.addAll(lines);
    return result;
  }

  Lines._();

  factory Lines.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Lines()..mergeFromBuffer(data, registry);
  factory Lines.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Lines()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Lines',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'),
      createEmptyInstance: Lines.$_createMessage)
    ..pPM<Line>(1, _omitFieldNames ? '' : 'lines',
        subBuilder: Line.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Lines clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Lines copyWith(void Function(Lines) updates) =>
      super.copyWith((message) => updates(message as Lines)) as Lines;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Lines() / Lines.new instead')
  static Lines create() => Lines._();
  static $pb.GeneratedMessage $_createMessage() => Lines._();
  @$core.override
  Lines createEmptyInstance() => Lines._();
  @$core.pragma('dart2js:noInline')
  static Lines getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Lines>(Lines.$_createMessage);
  static Lines? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Line> get lines => $_getList(0);
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
    final result = Nearby._();
    if (veh != null) result.veh = veh;
    if (ts != null) result.ts = ts;
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (spd != null) result.spd = spd;
    if (hdg != null) result.hdg = hdg;
    if (distM != null) result.distM = distM;
    return result;
  }

  Nearby._();

  factory Nearby.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Nearby()..mergeFromBuffer(data, registry);
  factory Nearby.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Nearby()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Nearby',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'),
      createEmptyInstance: Nearby.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'veh', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'ts', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'lat', fieldType: $pb.PbFieldType.OS3)
    ..aI(4, _omitFieldNames ? '' : 'lon', fieldType: $pb.PbFieldType.OS3)
    ..aI(5, _omitFieldNames ? '' : 'spd', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'hdg', fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'distM', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Nearby clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Nearby copyWith(void Function(Nearby) updates) =>
      super.copyWith((message) => updates(message as Nearby)) as Nearby;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Nearby() / Nearby.new instead')
  static Nearby create() => Nearby._();
  static $pb.GeneratedMessage $_createMessage() => Nearby._();
  @$core.override
  Nearby createEmptyInstance() => Nearby._();
  @$core.pragma('dart2js:noInline')
  static Nearby getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Nearby>(Nearby.$_createMessage);
  static Nearby? _defaultInstance;

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

  @$pb.TagNumber(7)
  $core.int get distM => $_getIZ(6);
  @$pb.TagNumber(7)
  set distM($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDistM() => $_has(6);
  @$pb.TagNumber(7)
  void clearDistM() => $_clearField(7);
}

class NearbyList extends $pb.GeneratedMessage {
  factory NearbyList({
    $core.Iterable<Nearby>? vehicles,
  }) {
    final result = NearbyList._();
    if (vehicles != null) result.vehicles.addAll(vehicles);
    return result;
  }

  NearbyList._();

  factory NearbyList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NearbyList()..mergeFromBuffer(data, registry);
  factory NearbyList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NearbyList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NearbyList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'),
      createEmptyInstance: NearbyList.$_createMessage)
    ..pPM<Nearby>(1, _omitFieldNames ? '' : 'vehicles',
        subBuilder: Nearby.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NearbyList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NearbyList copyWith(void Function(NearbyList) updates) =>
      super.copyWith((message) => updates(message as NearbyList)) as NearbyList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NearbyList() / NearbyList.new instead')
  static NearbyList create() => NearbyList._();
  static $pb.GeneratedMessage $_createMessage() => NearbyList._();
  @$core.override
  NearbyList createEmptyInstance() => NearbyList._();
  @$core.pragma('dart2js:noInline')
  static NearbyList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NearbyList>(NearbyList.$_createMessage);
  static NearbyList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Nearby> get vehicles => $_getList(0);
}

/// GET /ruta?veh&lat&lon — road route from the vehicle to the passenger
class Route extends $pb.GeneratedMessage {
  factory Route({
    $core.String? polyline,
    $core.int? distM,
    $core.int? timeS,
  }) {
    final result = Route._();
    if (polyline != null) result.polyline = polyline;
    if (distM != null) result.distM = distM;
    if (timeS != null) result.timeS = timeS;
    return result;
  }

  Route._();

  factory Route.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Route()..mergeFromBuffer(data, registry);
  factory Route.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Route()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Route',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'),
      createEmptyInstance: Route.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'polyline')
    ..aI(2, _omitFieldNames ? '' : 'distM', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'timeS', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Route clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Route copyWith(void Function(Route) updates) =>
      super.copyWith((message) => updates(message as Route)) as Route;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Route() / Route.new instead')
  static Route create() => Route._();
  static $pb.GeneratedMessage $_createMessage() => Route._();
  @$core.override
  Route createEmptyInstance() => Route._();
  @$core.pragma('dart2js:noInline')
  static Route getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Route>(Route.$_createMessage);
  static Route? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get polyline => $_getSZ(0);
  @$pb.TagNumber(1)
  set polyline($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPolyline() => $_has(0);
  @$pb.TagNumber(1)
  void clearPolyline() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get distM => $_getIZ(1);
  @$pb.TagNumber(2)
  set distM($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDistM() => $_has(1);
  @$pb.TagNumber(2)
  void clearDistM() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get timeS => $_getIZ(2);
  @$pb.TagNumber(3)
  set timeS($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeS() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeS() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
