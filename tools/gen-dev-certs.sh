#!/usr/bin/env bash
# Development TLS: a local CA + an ECDSA P-256 server certificate for EMQX (8883) and the backend (8443).
# ECDSA keeps the certificate chain (and so every full TLS handshake) small, which matters for the data budget.
#
#   bash tools/gen-dev-certs.sh [extra IPs...]   # LAN IPs of this PC are added automatically
#
# Output (git-ignored): certs/ca.crt, certs/server.crt, certs/server.key
# Also copies ca.crt to app/assets/certs/dev-ca.pem (trusted by debug builds run with --dart-define=DEV_CA=true).
# Production uses a real certificate (e.g. Let's Encrypt) and the system trust store instead.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/certs" "$ROOT/app/assets/certs"
# openssl may be a native Windows binary: give it Windows-style paths and keep MSYS from rewriting "/CN=..."
native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
OUT="$(native "$ROOT/certs")"
export MSYS_NO_PATHCONV=1

IPS=("127.0.0.1" "10.0.2.2" "$@")
if command -v powershell >/dev/null; then
  while read -r ip; do [ -n "$ip" ] && IPS+=("$ip"); done < <(powershell -NoProfile -Command \
    "Get-NetIPAddress -AddressFamily IPv4 | ? { \$_.IPAddress -notlike '127.*' -and \$_.IPAddress -notlike '169.254.*' -and \$_.InterfaceAlias -notmatch 'vEthernet|WSL|Loopback|Docker' } | % IPAddress" | tr -d '\r')
fi
SAN="DNS:localhost,DNS:emqx,DNS:backend"
for ip in "${IPS[@]}"; do SAN="$SAN,IP:$ip"; done

if [ ! -f "$OUT/ca.key" ]; then
  openssl ecparam -name prime256v1 -genkey -noout -out "$OUT/ca.key"
  openssl req -x509 -new -key "$OUT/ca.key" -sha256 -days 3650 -subj "/CN=TransMcbo Dev CA" -out "$OUT/ca.crt"
fi

openssl ecparam -name prime256v1 -genkey -noout -out "$OUT/server.key"
printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\nkeyUsage=digitalSignature\n' "$SAN" > "$OUT/server.ext"
openssl req -new -key "$OUT/server.key" -subj "/CN=transmcbo-dev" -out "$OUT/server.csr"
openssl x509 -req -in "$OUT/server.csr" -CA "$OUT/ca.crt" -CAkey "$OUT/ca.key" -CAcreateserial -sha256 -days 825 \
  -extfile "$OUT/server.ext" -out "$OUT/server.crt"
rm -f "$OUT/server.csr" "$OUT/server.ext"
chmod 644 "$OUT/server.key" # EMQX runs as a non-root user inside the container

cp "$OUT/ca.crt" "$ROOT/app/assets/certs/dev-ca.pem"
openssl x509 -in "$OUT/server.crt" -noout -ext subjectAltName
