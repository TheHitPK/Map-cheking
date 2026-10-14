#!/usr/bin/env bash
# Extracts the offline vector map of Maracaibo from the public Protomaps daily build.
# Output: app/assets/maps/maracaibo.pmtiles (bundled in the passenger APK). Requires only Docker.
# Only the tiles inside the bbox are downloaded (HTTP range requests), not the planet.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/app/assets/maps"
BBOX="-72.0,10.40,-71.40,10.95"   # same service area as the backend (Geo.MIN/MAX_LAT/LON)
MAXZOOM="${MAXZOOM:-14}"          # vector tiles overzoom fine beyond 14; each extra level ~x4 size
BUILD="${BUILD:-$(curl -fsSL https://build-metadata.protomaps.dev/builds.json | grep -oE '"key":"[0-9]+\.pmtiles"' | tail -1 | sed 's/"key":"//; s/"//')}"

mkdir -p "$OUT_DIR"
export MSYS_NO_PATHCONV=1
host_path() { if command -v cygpath >/dev/null; then cygpath -w "$1"; else echo "$1"; fi; }

echo "Protomaps build: $BUILD, maxzoom $MAXZOOM"
docker run --rm -v "$(host_path "$OUT_DIR"):/out" protomaps/go-pmtiles:v1.28.0 \
  extract "https://build.protomaps.com/$BUILD" /out/maracaibo.pmtiles --bbox="$BBOX" --maxzoom="$MAXZOOM"

[ -s "$OUT_DIR/maracaibo.pmtiles" ] || { echo "ERROR: empty output" >&2; exit 1; }
ls -lh "$OUT_DIR/maracaibo.pmtiles"
