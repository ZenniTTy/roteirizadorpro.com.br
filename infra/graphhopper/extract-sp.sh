#!/usr/bin/env bash
# Extract the capital São Paulo OSM bbox from the Sudeste regional PBF.
#
# Idempotent: skips download if the source PBF exists; skips extract if the
# output PBF is newer than the source.
#
# Bbox (capital SP only — M1 reduced configuration to fit the 1 GB droplet).
# Post-M1 the droplet is resized and the Sudeste full PBF replaces this. See
# ADR-0008.
#
#   left,bottom,right,top = -46.83,-23.78,-46.40,-23.36
#
# Run from anywhere — paths resolve relative to this script.

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
# Honor GH_DATA_DIR for local devs who relocated heavy data outside the repo
# (see ../../roteirizadorpro-infra-data/). Falls back to the in-repo path for
# CI/production parity with docker-compose.yml's default bind-mount.
PBF_DIR="${GH_DATA_DIR:-$DIR/data}/pbf"
SRC="$PBF_DIR/sudeste-latest.osm.pbf"
DST="$PBF_DIR/sao-paulo-capital.osm.pbf"
SRC_URL="https://download.geofabrik.de/south-america/brazil/sudeste-latest.osm.pbf"
BBOX="-46.83,-23.78,-46.40,-23.36"

mkdir -p "$PBF_DIR"

if ! command -v osmium >/dev/null 2>&1; then
  echo "osmium-tool not found. Install with: brew install osmium-tool" >&2
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "Downloading $SRC_URL → $SRC ..."
  curl -fL -o "$SRC.tmp" "$SRC_URL"
  mv "$SRC.tmp" "$SRC"
fi

if [[ -f "$DST" && "$DST" -nt "$SRC" ]]; then
  echo "✓ $DST already up-to-date"
else
  echo "Extracting bbox $BBOX → $DST ..."
  osmium extract --bbox "$BBOX" --strategy smart --overwrite --output "$DST" "$SRC"
fi

echo "--- summary"
osmium fileinfo "$DST" | grep -E '^  (Bounding box|Number of (nodes|ways|relations)):' || true
ls -lh "$DST"
