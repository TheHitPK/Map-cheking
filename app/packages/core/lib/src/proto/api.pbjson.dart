//
//  Generated code. Do not modify.
//  source: api.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use lineDescriptor instead')
const Line$json = {
  '1': 'Line',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `Line`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lineDescriptor = $convert.base64Decode(
    'CgRMaW5lEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1l');

@$core.Deprecated('Use linesDescriptor instead')
const Lines$json = {
  '1': 'Lines',
  '2': [
    {'1': 'lines', '3': 1, '4': 3, '5': 11, '6': '.transmcbo.v1.Line', '10': 'lines'},
  ],
};

/// Descriptor for `Lines`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List linesDescriptor = $convert.base64Decode(
    'CgVMaW5lcxIoCgVsaW5lcxgBIAMoCzISLnRyYW5zbWNiby52MS5MaW5lUgVsaW5lcw==');

@$core.Deprecated('Use nearbyDescriptor instead')
const Nearby$json = {
  '1': 'Nearby',
  '2': [
    {'1': 'veh', '3': 1, '4': 1, '5': 13, '10': 'veh'},
    {'1': 'ts', '3': 2, '4': 1, '5': 13, '10': 'ts'},
    {'1': 'lat', '3': 3, '4': 1, '5': 17, '10': 'lat'},
    {'1': 'lon', '3': 4, '4': 1, '5': 17, '10': 'lon'},
    {'1': 'spd', '3': 5, '4': 1, '5': 13, '10': 'spd'},
    {'1': 'hdg', '3': 6, '4': 1, '5': 13, '10': 'hdg'},
    {'1': 'dist_m', '3': 7, '4': 1, '5': 13, '10': 'distM'},
  ],
};

/// Descriptor for `Nearby`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nearbyDescriptor = $convert.base64Decode(
    'CgZOZWFyYnkSEAoDdmVoGAEgASgNUgN2ZWgSDgoCdHMYAiABKA1SAnRzEhAKA2xhdBgDIAEoEV'
    'IDbGF0EhAKA2xvbhgEIAEoEVIDbG9uEhAKA3NwZBgFIAEoDVIDc3BkEhAKA2hkZxgGIAEoDVID'
    'aGRnEhUKBmRpc3RfbRgHIAEoDVIFZGlzdE0=');

@$core.Deprecated('Use nearbyListDescriptor instead')
const NearbyList$json = {
  '1': 'NearbyList',
  '2': [
    {'1': 'vehicles', '3': 1, '4': 3, '5': 11, '6': '.transmcbo.v1.Nearby', '10': 'vehicles'},
  ],
};

/// Descriptor for `NearbyList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nearbyListDescriptor = $convert.base64Decode(
    'CgpOZWFyYnlMaXN0EjAKCHZlaGljbGVzGAEgAygLMhQudHJhbnNtY2JvLnYxLk5lYXJieVIIdm'
    'VoaWNsZXM=');

@$core.Deprecated('Use routeDescriptor instead')
const Route$json = {
  '1': 'Route',
  '2': [
    {'1': 'polyline', '3': 1, '4': 1, '5': 9, '10': 'polyline'},
    {'1': 'dist_m', '3': 2, '4': 1, '5': 13, '10': 'distM'},
    {'1': 'time_s', '3': 3, '4': 1, '5': 13, '10': 'timeS'},
  ],
};

/// Descriptor for `Route`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routeDescriptor = $convert.base64Decode(
    'CgVSb3V0ZRIaCghwb2x5bGluZRgBIAEoCVIIcG9seWxpbmUSFQoGZGlzdF9tGAIgASgNUgVkaX'
    'N0TRIVCgZ0aW1lX3MYAyABKA1SBXRpbWVT');

