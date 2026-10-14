#!/usr/bin/env bash
# Generates Dart classes for proto/*.proto into app/packages/core/lib/src/proto.
# Uses the protoc binary Maven already downloaded (backend build) and protoc_plugin:
#   dart pub global activate protoc_plugin 25.1.0
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/app/packages/core/lib/src/proto"
PROTOC_VERSION="4.36.2"   # keep in sync with protobuf.version in backend/pom.xml

PROTOC="$(find "$HOME/.m2/repository/com/google/protobuf/protoc/$PROTOC_VERSION" -name 'protoc-*' -type f ! -name '*.sha1' | head -1)"
if [ -z "$PROTOC" ]; then
  echo "protoc $PROTOC_VERSION not found: run ./mvnw generate-sources in backend/ first" >&2
  exit 1
fi
chmod +x "$PROTOC" 2>/dev/null || true

PLUGIN_DIR="${PUB_CACHE:-$([ -n "${LOCALAPPDATA:-}" ] && echo "$LOCALAPPDATA/Pub/Cache" || echo "$HOME/.pub-cache")}/bin"
PLUGIN="$PLUGIN_DIR/protoc-gen-dart"
[ -f "$PLUGIN.bat" ] && PLUGIN="$PLUGIN.bat"

rm -rf "$OUT" && mkdir -p "$OUT"
"$PROTOC" --plugin="protoc-gen-dart=$PLUGIN" -I "$ROOT/proto" --dart_out="$OUT" "$ROOT"/proto/*.proto
ls "$OUT"
