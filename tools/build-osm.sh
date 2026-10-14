#!/usr/bin/env bash
# Downloads Venezuela from Geofabrik and clips it to the service area (Maracaibo + San Francisco).
# Output: data/maracaibo.osm.pbf (GraphHopper input) and backend test fixture.
# Requires only Docker.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="$ROOT/data"
FIXTURE_DIR="$ROOT/backend/src/test/resources/osm"
SOURCE_URL="https://download.geofabrik.de/south-america/venezuela-latest.osm.pbf"
# Must match Geo.MIN/MAX_LAT/LON in the backend: minlon,minlat,maxlon,maxlat
SERVICE_BBOX="-72.0,10.40,-71.40,10.95"
MARGIN_BBOX="-72.1,10.30,-71.30,11.05"
# Small piece of downtown Maracaibo for integration tests
FIXTURE_BBOX="-71.635,10.635,-71.600,10.665"

mkdir -p "$DATA" "$FIXTURE_DIR"

# Git Bash on Windows: stop MSYS from rewriting container paths
export MSYS_NO_PATHCONV=1
host_path() { if command -v cygpath >/dev/null; then cygpath -w "$1"; else echo "$1"; fi; }

docker run --rm \
  -v "$(host_path "$DATA"):/data" \
  -v "$(host_path "$FIXTURE_DIR"):/fixture" \
  debian:bookworm-slim bash -c "
    set -euo pipefail
    apt-get update -qq && apt-get install -y -qq osmium-tool curl ca-certificates >/dev/null
    cd /data
    curl -fsSL -o venezuela-latest.osm.pbf.md5 '$SOURCE_URL.md5'
    if ! md5sum -c --status venezuela-latest.osm.pbf.md5 2>/dev/null; then
      curl -fsSL -o venezuela-latest.osm.pbf '$SOURCE_URL'
      md5sum -c venezuela-latest.osm.pbf.md5
    fi
    # Two steps keep memory low (Docker may have ~2 GB): a cheap 'simple' cut with a margin,
    # then 'complete_ways' on the small file so roads crossing the border stay whole.
    osmium extract --overwrite --strategy simple -b '$MARGIN_BBOX' venezuela-latest.osm.pbf -o /tmp/margin.osm.pbf
    osmium extract --overwrite --strategy complete_ways -b '$SERVICE_BBOX' /tmp/margin.osm.pbf -o maracaibo.osm.pbf
    osmium extract --overwrite --strategy complete_ways -b '$FIXTURE_BBOX' maracaibo.osm.pbf -o /fixture/maracaibo-centro.osm.pbf
  "

for f in "$DATA/maracaibo.osm.pbf" "$FIXTURE_DIR/maracaibo-centro.osm.pbf"; do
  [ -s "$f" ] || { echo "ERROR: $f missing or empty" >&2; exit 1; }
done
ls -lh "$DATA/maracaibo.osm.pbf" "$FIXTURE_DIR/maracaibo-centro.osm.pbf"
echo "Delete $DATA/../graph-cache to force GraphHopper to re-import."
