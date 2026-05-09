#!/usr/bin/env bash
# GraphHopper p95 benchmark — Roteirizador Pro M1 acceptance criterion #3.
#
# Methodology:
#   - N=100 routes (override with BENCH_N=NN)
#   - Sequential, no concurrency, no warmup (matches single-shot user latency)
#   - Random point pairs inside the capital-SP bbox; GraphHopper snaps to
#     nearest road, so coordinates landing on rooftops/water still resolve.
#   - Failed requests (non-200, e.g. PointNotFound on the reservoir middle)
#     are counted but excluded from latency stats.
#
# Output: min / p50 / mean / p95 / p99 / max, plus error count.

set -euo pipefail

N=${BENCH_N:-100}
HOST=${BENCH_HOST:-http://127.0.0.1:8989}
PROFILE=${BENCH_PROFILE:-motorcycle}

# Capital São Paulo bbox (matches infra/graphhopper/extract-sp.sh)
LAT_MIN=-23.78
LAT_MAX=-23.36
LNG_MIN=-46.83
LNG_MAX=-46.40

ROUTES=$(awk -v n="$N" \
  -v lat_min="$LAT_MIN" -v lat_max="$LAT_MAX" \
  -v lng_min="$LNG_MIN" -v lng_max="$LNG_MAX" '
  BEGIN{
    srand();
    for (i=0; i<n; i++) {
      lat1=lat_min+rand()*(lat_max-lat_min)
      lng1=lng_min+rand()*(lng_max-lng_min)
      lat2=lat_min+rand()*(lat_max-lat_min)
      lng2=lng_min+rand()*(lng_max-lng_min)
      printf "%.6f,%.6f %.6f,%.6f\n", lat1, lng1, lat2, lng2
    }
  }')

times_file=$(mktemp)
errors=0
total=0

trap 'rm -f "$times_file"' EXIT

while read -r p1 p2; do
  total=$((total+1))
  out=$(curl -s -o /dev/null -w '%{http_code} %{time_total}' \
    "$HOST/route?point=$p1&point=$p2&profile=$PROFILE")
  http=$(awk '{print $1}' <<< "$out")
  t=$(awk '{print $2}' <<< "$out")
  if [[ "$http" == "200" ]]; then
    echo "$t" >> "$times_file"
  else
    errors=$((errors+1))
  fi
  printf "\r  %d/%d (errors=%d)" "$total" "$N" "$errors" >&2
done <<< "$ROUTES"
echo >&2

sort -n "$times_file" | awk '
  {a[NR]=$1; sum+=$1}
  END {
    if (NR==0) { print "ERROR: no successful requests"; exit 1 }
    p50_i=int(NR*0.50+0.5); if (p50_i<1) p50_i=1
    p95_i=int(NR*0.95+0.5); if (p95_i<1) p95_i=1
    p99_i=int(NR*0.99+0.5); if (p99_i<1) p99_i=1
    printf "n     = %d\n",       NR
    printf "min   = %.4fs\n",    a[1]
    printf "p50   = %.4fs\n",    a[p50_i]
    printf "mean  = %.4fs\n",    sum/NR
    printf "p95   = %.4fs\n",    a[p95_i]
    printf "p99   = %.4fs\n",    a[p99_i]
    printf "max   = %.4fs\n",    a[NR]
  }'

echo "errors = $errors / $total (excluded from stats)"
