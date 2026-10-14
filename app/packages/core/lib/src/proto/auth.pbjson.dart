//
//  Generated code. Do not modify.
//  source: auth.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use driverLoginDescriptor instead')
const DriverLogin$json = {
  '1': 'DriverLogin',
  '2': [
    {'1': 'veh', '3': 1, '4': 1, '5': 13, '10': 'veh'},
    {'1': 'pin', '3': 2, '4': 1, '5': 9, '10': 'pin'},
    {'1': 'line', '3': 3, '4': 1, '5': 9, '10': 'line'},
  ],
};

/// Descriptor for `DriverLogin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List driverLoginDescriptor = $convert.base64Decode(
    'CgtEcml2ZXJMb2dpbhIQCgN2ZWgYASABKA1SA3ZlaBIQCgNwaW4YAiABKAlSA3BpbhISCgRsaW'
    '5lGAMgASgJUgRsaW5l');

@$core.Deprecated('Use tokenDescriptor instead')
const Token$json = {
  '1': 'Token',
  '2': [
    {'1': 'jwt', '3': 1, '4': 1, '5': 9, '10': 'jwt'},
    {'1': 'exp', '3': 2, '4': 1, '5': 13, '10': 'exp'},
    {'1': 'username', '3': 3, '4': 1, '5': 9, '10': 'username'},
    {'1': 'mqtt_host', '3': 4, '4': 1, '5': 9, '10': 'mqttHost'},
    {'1': 'mqtt_port', '3': 5, '4': 1, '5': 13, '10': 'mqttPort'},
    {'1': 'mqtt_tls', '3': 6, '4': 1, '5': 8, '10': 'mqttTls'},
  ],
};

/// Descriptor for `Token`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tokenDescriptor = $convert.base64Decode(
    'CgVUb2tlbhIQCgNqd3QYASABKAlSA2p3dBIQCgNleHAYAiABKA1SA2V4cBIaCgh1c2VybmFtZR'
    'gDIAEoCVIIdXNlcm5hbWUSGwoJbXF0dF9ob3N0GAQgASgJUghtcXR0SG9zdBIbCgltcXR0X3Bv'
    'cnQYBSABKA1SCG1xdHRQb3J0EhkKCG1xdHRfdGxzGAYgASgIUgdtcXR0VGxz');

