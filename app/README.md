# app

Flutter, un proyecto con dos flavors y el paquete compartido `packages/core`.

```sh
flutter run --flavor chofer   -t lib/main_chofer.dart
flutter run --flavor pasajero -t lib/main_pasajero.dart
# backend fuera del emulador:
flutter run --flavor pasajero -t lib/main_pasajero.dart --dart-define=API_URL=http://192.168.1.10:8080 --dart-define=MQTT_HOST=192.168.1.10
```

- `packages/core`: protocolo (Protobuf), geo, snap a la polyline + ETA, cliente HTTP y MQTT 5.
- Protobuf: `bash ../tools/gen-dart-proto.sh` regenera `packages/core/lib/src/proto` (protobuf ^3: lo exige `vector_map_tiles`).
- Mapa offline: `bash ../tools/build-pmtiles.sh` regenera `assets/maps/maracaibo.pmtiles` (Protomaps, z0–14, ~3 MB).
- Tests: `cd packages/core && flutter test`.
