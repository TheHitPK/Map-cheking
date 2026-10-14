#!/usr/bin/env bash
# Prints the SQL to register (or re-PIN) a driver unit. The PIN is hashed with the backend's PinHasher (PBKDF2).
#   bash tools/new-vehicle.sh <unidad> <pin>     e.g. bash tools/new-vehicle.sh 12 4821
# Run the printed SQL in the production database (Render: transmcbo-db -> Connect -> PSQL command).
set -euo pipefail

VEH="${1:?usage: new-vehicle.sh <unidad> <pin>}"
PIN="${2:?usage: new-vehicle.sh <unidad> <pin>}"
[[ "$VEH" =~ ^[1-9][0-9]{0,9}$ ]] || { echo "unidad must be a positive integer" >&2; exit 1; }
[[ "$PIN" =~ ^[0-9]{4,8}$ ]] || { echo "PIN must be 4-8 digits" >&2; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSHELL="${JAVA_HOME:+$JAVA_HOME/bin/}jshell"
(cd "$ROOT/backend" && sh mvnw -q -B compile >&2)
HASH="$(printf 'System.out.println(com.transmcbo.auth.PinHasher.hash("%s"));\n/exit\n' "$PIN" \
  | "$JSHELL" --class-path "$ROOT/backend/target/classes" -q 2>/dev/null | grep -o 'pbkdf2\$[^[:space:]]*' | tr -d '\r')"
[ -n "$HASH" ] || { echo "could not hash the PIN (is JDK 21 jshell on PATH or JAVA_HOME?)" >&2; exit 1; }

echo "INSERT INTO vehicle (id, pin_hash) VALUES ($VEH, '$HASH')"
echo "  ON CONFLICT (id) DO UPDATE SET pin_hash = EXCLUDED.pin_hash, active = true;"
