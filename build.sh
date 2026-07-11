#!/usr/bin/env bash
# Build the QRgen core under Nimony (Nim 3).
#
# QRgen has zero external dependencies, so this just compiles the public module
# through a tiny smoke program. Nimony resolves imports via `nimony.paths`
# (which lists `src`). Set NIMONY=... to override the toolchain.
#
#   ./build.sh          # compile a smoke program that imports QRgen
#   ./build.sh --run    # ...and run it
set -eu
cd "$(dirname "$0")"
NIMONY="${NIMONY:-../nimony/bin/nimony}"
[ -x "$NIMONY" ] || { echo "nimony not found at $NIMONY (set NIMONY=...)" >&2; exit 2; }
mkdir -p .build

smoke="$(mktemp -d)/smoke.nim"
cat > "$smoke" <<'EOF'
import std/syncio
import QRgen
try:
  let qr = newQR("https://example.com/device?user_code=WDJB-MJHT", qrECM)
  echo "QRgen ok: version ", int(qr.version), " size ", int(qr.drawing.size)
except:
  echo "QRgen: data does not fit"
EOF

run=""
[ "${1:-}" = "--run" ] && run="-r"
"$NIMONY" c $run --path:src --out:.build/smoke "$smoke"
echo "built .build/smoke"
