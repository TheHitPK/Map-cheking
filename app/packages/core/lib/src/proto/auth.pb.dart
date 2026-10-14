//
//  Generated code. Do not modify.
//  source: auth.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// POST /auth/chofer
class DriverLogin extends $pb.GeneratedMessage {
  factory DriverLogin({
    $core.int? veh,
    $core.String? pin,
    $core.String? line,
  }) {
    final $result = create();
    if (veh != null) {
      $result.veh = veh;
    }
    if (pin != null) {
      $result.pin = pin;
    }
    if (line != null) {
      $result.line = line;
    }
    return $result;
  }
  DriverLogin._() : super();
  factory DriverLogin.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DriverLogin.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DriverLogin', package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'veh', $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'pin')
    ..aOS(3, _omitFieldNames ? '' : 'line')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DriverLogin clone() => DriverLogin()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DriverLogin copyWith(void Function(DriverLogin) updates) => super.copyWith((message) => updates(message as DriverLogin)) as DriverLogin;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DriverLogin create() => DriverLogin._();
  DriverLogin createEmptyInstance() => create();
  static $pb.PbList<DriverLogin> createRepeated() => $pb.PbList<DriverLogin>();
  @$core.pragma('dart2js:noInline')
  static DriverLogin getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DriverLogin>(create);
  static DriverLogin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get veh => $_getIZ(0);
  @$pb.TagNumber(1)
  set veh($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVeh() => $_has(0);
  @$pb.TagNumber(1)
  void clearVeh() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get pin => $_getSZ(1);
  @$pb.TagNumber(2)
  set pin($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPin() => $_has(1);
  @$pb.TagNumber(2)
  void clearPin() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get line => $_getSZ(2);
  @$pb.TagNumber(3)
  set line($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLine() => $_has(2);
  @$pb.TagNumber(3)
  void clearLine() => clearField(3);
}

/// Response of POST /auth/chofer and /auth/pasajero. Use `jwt` as the MQTT password.
class Token extends $pb.GeneratedMessage {
  factory Token({
    $core.String? jwt,
    $core.int? exp,
  }) {
    final $result = create();
    if (jwt != null) {
      $result.jwt = jwt;
    }
    if (exp != null) {
      $result.exp = exp;
    }
    return $result;
  }
  Token._() : super();
  factory Token.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Token.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Token', package: const $pb.PackageName(_omitMessageNames ? '' : 'transmcbo.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jwt')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'exp', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Token clone() => Token()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Token copyWith(void Function(Token) updates) => super.copyWith((message) => updates(message as Token)) as Token;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Token create() => Token._();
  Token createEmptyInstance() => create();
  static $pb.PbList<Token> createRepeated() => $pb.PbList<Token>();
  @$core.pragma('dart2js:noInline')
  static Token getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Token>(create);
  static Token? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jwt => $_getSZ(0);
  @$pb.TagNumber(1)
  set jwt($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasJwt() => $_has(0);
  @$pb.TagNumber(1)
  void clearJwt() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get exp => $_getIZ(1);
  @$pb.TagNumber(2)
  set exp($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasExp() => $_has(1);
  @$pb.TagNumber(2)
  void clearExp() => clearField(2);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
