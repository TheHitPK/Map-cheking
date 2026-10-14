// This is a generated file - do not edit.
//
// Generated from pos.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use posDescriptor instead')
const Pos$json = {
  '1': 'Pos',
  '2': [
    {'1': 'veh', '3': 1, '4': 1, '5': 13, '10': 'veh'},
    {'1': 'ts', '3': 2, '4': 1, '5': 13, '10': 'ts'},
    {'1': 'lat', '3': 3, '4': 1, '5': 17, '10': 'lat'},
    {'1': 'lon', '3': 4, '4': 1, '5': 17, '10': 'lon'},
    {'1': 'spd', '3': 5, '4': 1, '5': 13, '10': 'spd'},
    {'1': 'hdg', '3': 6, '4': 1, '5': 13, '10': 'hdg'},
  ],
};

/// Descriptor for `Pos`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List posDescriptor = $convert.base64Decode(
    'CgNQb3MSEAoDdmVoGAEgASgNUgN2ZWgSDgoCdHMYAiABKA1SAnRzEhAKA2xhdBgDIAEoEVIDbG'
    'F0EhAKA2xvbhgEIAEoEVIDbG9uEhAKA3NwZBgFIAEoDVIDc3BkEhAKA2hkZxgGIAEoDVIDaGRn');

@$core.Deprecated('Use posBatchDescriptor instead')
const PosBatch$json = {
  '1': 'PosBatch',
  '2': [
    {
      '1': 'first',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.transmcbo.v1.Pos',
      '10': 'first'
    },
    {'1': 'dts', '3': 2, '4': 3, '5': 17, '10': 'dts'},
    {'1': 'dlat', '3': 3, '4': 3, '5': 17, '10': 'dlat'},
    {'1': 'dlon', '3': 4, '4': 3, '5': 17, '10': 'dlon'},
    {'1': 'spd', '3': 5, '4': 3, '5': 13, '10': 'spd'},
    {'1': 'hdg', '3': 6, '4': 3, '5': 13, '10': 'hdg'},
  ],
};

/// Descriptor for `PosBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List posBatchDescriptor = $convert.base64Decode(
    'CghQb3NCYXRjaBInCgVmaXJzdBgBIAEoCzIRLnRyYW5zbWNiby52MS5Qb3NSBWZpcnN0EhAKA2'
    'R0cxgCIAMoEVIDZHRzEhIKBGRsYXQYAyADKBFSBGRsYXQSEgoEZGxvbhgEIAMoEVIEZGxvbhIQ'
    'CgNzcGQYBSADKA1SA3NwZBIQCgNoZGcYBiADKA1SA2hkZw==');
