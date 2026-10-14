// This is a generated file - do not edit.
//
// Generated from auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// POST /auth/chofer
class DriverLogin extends $pb.GeneratedMessage {
  factory DriverLogin({
    $core.int? veh,
    $core.String? pin,
    $core.String? line,
  }) {
    final result = DriverLogin._();
    if (veh != null) result.veh = veh;
    if (pin != null) result.pin = pin;
    if (line != null) result.line = line;
    return result;
  }

  DriverLogin._();

  factory DriverLogin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DriverLogin()..mergeFromBuffer(data, registry);
  factory DriverLogin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DriverLogin()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DriverLogin',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'),
      createEmptyInstance: DriverLogin.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'veh', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'pin')
    ..aOS(3, _omitFieldNames ? '' : 'line')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DriverLogin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DriverLogin copyWith(void Function(DriverLogin) updates) =>
      super.copyWith((message) => updates(message as DriverLogin))
          as DriverLogin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DriverLogin() / DriverLogin.new instead')
  static DriverLogin create() => DriverLogin._();
  static $pb.GeneratedMessage $_createMessage() => DriverLogin._();
  @$core.override
  DriverLogin createEmptyInstance() => DriverLogin._();
  @$core.pragma('dart2js:noInline')
  static DriverLogin getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DriverLogin>(
          DriverLogin.$_createMessage);
  static DriverLogin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get veh => $_getIZ(0);
  @$pb.TagNumber(1)
  set veh($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVeh() => $_has(0);
  @$pb.TagNumber(1)
  void clearVeh() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get pin => $_getSZ(1);
  @$pb.TagNumber(2)
  set pin($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPin() => $_has(1);
  @$pb.TagNumber(2)
  void clearPin() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get line => $_getSZ(2);
  @$pb.TagNumber(3)
  set line($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLine() => $_has(2);
  @$pb.TagNumber(3)
  void clearLine() => $_clearField(3);
}

/// Response of POST /auth/chofer and /auth/pasajero. Use `jwt` as the MQTT password.
class Token extends $pb.GeneratedMessage {
  factory Token({
    $core.String? jwt,
    $core.int? exp,
  }) {
    final result = Token._();
    if (jwt != null) result.jwt = jwt;
    if (exp != null) result.exp = exp;
    return result;
  }

  Token._();

  factory Token.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Token()..mergeFromBuffer(data, registry);
  factory Token.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Token()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Token',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'),
      createEmptyInstance: Token.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'jwt')
    ..aI(2, _omitFieldNames ? '' : 'exp', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Token clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Token copyWith(void Function(Token) updates) =>
      super.copyWith((message) => updates(message as Token)) as Token;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Token() / Token.new instead')
  static Token create() => Token._();
  static $pb.GeneratedMessage $_createMessage() => Token._();
  @$core.override
  Token createEmptyInstance() => Token._();
  @$core.pragma('dart2js:noInline')
  static Token getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Token>(Token.$_createMessage);
  static Token? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jwt => $_getSZ(0);
  @$pb.TagNumber(1)
  set jwt($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJwt() => $_has(0);
  @$pb.TagNumber(1)
  void clearJwt() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get exp => $_getIZ(1);
  @$pb.TagNumber(2)
  set exp($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExp() => $_has(1);
  @$pb.TagNumber(2)
  void clearExp() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
