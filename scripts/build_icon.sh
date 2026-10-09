#!/usr/bin/env bash
set -euo pipefail

# Package the approved 1024px PNG, including its transparent Dock margins.
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${REPO_ROOT}/assets/AppIcon.png"
ICONSET="${REPO_ROOT}/assets/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$SOURCE" --out "${ICONSET}/icon_${size}x${size}.png" >/dev/null
  retina_size=$((size * 2))
  sips -z "$retina_size" "$retina_size" "$SOURCE" --out "${ICONSET}/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "${REPO_ROOT}/assets/AppIcon.icns"
echo "Packaged ${REPO_ROOT}/assets/AppIcon.icns"
