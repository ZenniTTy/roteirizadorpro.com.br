#!/usr/bin/env bash
# Roteirizador Pro — push the prepared GraphHopper graph cache from the
# developer laptop to the production droplet.
#
# Why this exists: building the graph from PBF on a 1 GB droplet OOMs during
# CH preparation (see ADR-0008 amendment). The graph is built locally on a
# beefier laptop instead, then this script ships the prepared cache. Once the
# droplet starts the GraphHopper container, it loads the cache as-is — no
# rebuild.
#
# Usage:
#   ./scripts/rsync-graph-cache.sh <user>@<host>
#   ./scripts/rsync-graph-cache.sh roteirizador@203.0.113.42
#
# The script:
#   1. Verifies the local graph-cache exists and is non-empty.
#   2. rsync's it to /opt/roteirizador/data/graphhopper/graph-cache/ on the droplet.
#   3. Also ships the source PBF, in case anyone on the droplet ever wants to
#      rebuild manually.
#   4. --delete on the destination so renamed/removed cache files don't linger.

set -euo pipefail

REMOTE="${1:-}"
if [[ -z "$REMOTE" ]]; then
  echo "Usage: $0 <user>@<host>" >&2
  exit 1
fi

DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_DIR="$DIR/infra/graphhopper/data"
REMOTE_DIR="/opt/roteirizador/data/graphhopper"

if [[ ! -d "$LOCAL_DIR/graph-cache" ]] || [[ -z "$(ls -A "$LOCAL_DIR/graph-cache" 2>/dev/null)" ]]; then
  echo "ERROR: $LOCAL_DIR/graph-cache is missing or empty." >&2
  echo "  Build it first:" >&2
  echo "    cd infra && docker compose --profile routing up -d graphhopper" >&2
  exit 1
fi

CACHE_BYTES=$(du -sk "$LOCAL_DIR/graph-cache" | awk '{print $1*1024}')
PBF_BYTES=$(du -sk "$LOCAL_DIR/pbf" 2>/dev/null | awk '{print $1*1024}' || echo 0)
echo "About to push to ${REMOTE}:${REMOTE_DIR}/"
echo "  graph-cache:  $(numfmt --to=iec --suffix=B "$CACHE_BYTES" 2>/dev/null || echo "$CACHE_BYTES bytes")"
echo "  pbf:          $(numfmt --to=iec --suffix=B "$PBF_BYTES"   2>/dev/null || echo "$PBF_BYTES bytes")"

rsync -avz --progress --delete \
  "$LOCAL_DIR/graph-cache/" \
  "${REMOTE}:${REMOTE_DIR}/graph-cache/"

# PBF is optional — graph-cache is sufficient for serving. Ship it so the
# droplet operator can rebuild if they ever need to (e.g., after editing config.yml).
if [[ -d "$LOCAL_DIR/pbf" ]] && [[ -n "$(ls -A "$LOCAL_DIR/pbf" 2>/dev/null)" ]]; then
  echo
  echo "Pushing pbf/ as well (optional, for on-droplet rebuild capability):"
  rsync -avz --progress \
    "$LOCAL_DIR/pbf/" \
    "${REMOTE}:${REMOTE_DIR}/pbf/"
fi

echo
echo "✓ done. Restart graphhopper on the droplet to pick up the cache:"
echo "    ssh ${REMOTE} 'cd /opt/roteirizador/compose && docker compose restart graphhopper'"
