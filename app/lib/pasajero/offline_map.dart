import 'dart:io';

import 'package:flutter/services.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

const mapAsset = 'assets/maps/maracaibo.pmtiles';

/// PMTiles needs random access, so the bundled asset is copied once to the app cache
/// (Directory.systemTemp is the app's cache dir on Android). No network involved.
Future<PmTilesVectorTileProvider> offlineTileProvider() async {
  final data = await rootBundle.load(mapAsset);
  final file = File('${Directory.systemTemp.path}/maracaibo.pmtiles');
  if (!await file.exists() || await file.length() != data.lengthInBytes) {
    await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
  }
  return PmTilesVectorTileProvider.fromSource(file.path);
}
