#!/usr/bin/env bash
# Roteirizador Pro — daily Postgres backup with 30-day rotation.
#
# Runs on the production droplet, intended for cron at 03:00 America/Sao_Paulo.
# Dumps the postgres container via docker exec + pg_dump (custom format,
# gzip compressed), writes timestamped file to /opt/roteirizador/backups/,
# rotates anything older than RETENTION_DAYS.
#
# Restore (manual):
#   gunzip -c /opt/roteirizador/backups/roteirizador-2026-05-26-030000.sql.gz \
#     | docker exec -i roteirizador-postgres psql -U roteirizador -d roteirizador
#
# Cron entry (install with: crontab -e):
#   0 3 * * * /opt/roteirizador/compose/repo/scripts/backup-postgres.sh \
#     >> /opt/roteirizador/logs/backup-postgres.log 2>&1

set -euo pipefail

CONTAINER="${CONTAINER:-roteirizador-postgres}"
DB_USER="${DB_USER:-roteirizador}"
DB_NAME="${DB_NAME:-roteirizador}"
BACKUP_DIR="${BACKUP_DIR:-/opt/roteirizador/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

ts="$(date -u +%Y-%m-%dT%H%M%SZ)"
out="$BACKUP_DIR/${DB_NAME}-${ts}.sql.gz"

log() { printf "[%s] %s\n" "$(date -u +%FT%TZ)" "$*"; }

mkdir -p "$BACKUP_DIR"

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
  log "ERROR: container $CONTAINER not found. Is the stack up?"
  exit 1
fi

log "dumping $DB_NAME from $CONTAINER → $out"
# pg_dump --clean --if-exists makes the dump self-restorable: drops objects
# before recreating, so a restore into a non-empty DB works without errors.
docker exec "$CONTAINER" pg_dump \
  --username="$DB_USER" \
  --dbname="$DB_NAME" \
  --clean \
  --if-exists \
  --no-owner \
  --no-acl \
  | gzip --best > "$out"

bytes=$(stat -c '%s' "$out" 2>/dev/null || stat -f '%z' "$out")
log "✓ dump completed (${bytes} bytes)"

log "rotating: removing dumps older than ${RETENTION_DAYS}d"
deleted=$(find "$BACKUP_DIR" -name "${DB_NAME}-*.sql.gz" -type f -mtime +"$RETENTION_DAYS" -print -delete | wc -l | tr -d ' ')
log "✓ rotation deleted $deleted file(s)"

log "current backups:"
ls -lh "$BACKUP_DIR"/${DB_NAME}-*.sql.gz 2>/dev/null | tail -10 || true
