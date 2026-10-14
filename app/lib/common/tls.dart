import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/services.dart';

import '../config.dart';

const _devCaAsset = 'assets/certs/dev-ca.pem';
const _devCaKey = 'dev_ca';

/// TLS trust for API + MQTT. Release: system roots (null). Debug with --dart-define=DEV_CA=true:
/// only the local CA from tools/gen-dev-certs.sh.
SecurityContext? _contextFrom(List<int>? pem) =>
    pem == null ? null : (SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(pem));

/// UI isolate: loads the dev CA from assets and stores it so the driver's service isolate can use it too.
Future<SecurityContext?> uiSecurityContext(AppDb db) async {
  if (!AppConfig.devCa) return null;
  final data = await rootBundle.load(_devCaAsset);
  final pem = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await db.putBytes(_devCaKey, pem);
  return _contextFrom(pem);
}

/// Background isolate (foreground service): reads what the UI stored.
Future<SecurityContext?> storedSecurityContext(AppDb db) async =>
    AppConfig.devCa ? _contextFrom(await db.getBytes(_devCaKey)) : null;

/// One HttpClient per isolate, so keep-alive avoids repeating the TLS handshake (no session resumption in dart:io).
HttpClient httpClientFor(SecurityContext? ctx) => HttpClient(context: ctx)..idleTimeout = const Duration(seconds: 60);
