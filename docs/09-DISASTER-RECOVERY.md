# 06 — Disaster Recovery

## Objectives

| Objective | Target |
|---|---|
| RTO (Recovery Time Objective) | 4 hours from incident detection to service restoration |
| RPO (Recovery Point Objective) | 24 hours of data loss maximum (driven by daily backup cadence) |

## Backups in Place

### PostgreSQL — Daily Logical Backup

- **Tool:** `pg_dump`.
- **Schedule:** 03:00 America/Sao_Paulo, daily, via cron.
- **Location:** `/opt/roteirizador/backups/postgres/YYYY-MM-DD.dump`.
- **Retention:** 30 days, rolling.
- **Verification:** Weekly automated restore test to a throwaway database (`scripts/verify-backup.sh`).
- **Off-site copy (recommended for post-M1):** Sync `/opt/roteirizador/backups/` to DigitalOcean Spaces or equivalent S3-compatible storage with `rclone`.

### DigitalOcean Droplet Snapshots

- **Cadence:** Manual snapshot before every major deploy. Quarterly snapshot as baseline.
- **Retention:** Keep at least the most recent snapshot at all times.
- **Cost:** ~$0.06/GB/month (small for an 8GB droplet).

### GraphHopper Graphs

- **Source of truth:** Geofabrik PBFs. Always reproducible.
- **Cache:** `/opt/roteirizador/data/graphhopper/graph-cache/` is the built graph. Rebuild takes 30–90 minutes if lost.
- **Backup:** None required. If the graph cache is lost, the recovery procedure is to re-import from PBFs.

### Application Code

- GitHub repo (`develop`, `main`, all tags). Two clones at minimum exist (Eduardo's local + GitHub remote). After handoff, the client's GitHub is the canonical remote.
- Server code does not need backup — it is rebuilt from `git pull` + Docker.

### Secrets

- Production secrets live only on the droplet at `/home/roteirizador/.env` with `chmod 600`.
- Backup of secrets: encrypted copy with the client (e.g., 1Password, Bitwarden vault). Eduardo provides the contents at handoff.
- **If the droplet is destroyed and secrets are not backed up off-server, every credential must be rotated on recovery** (Postgres password, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, JWT keys, etc.).

## Recovery Procedures

### Scenario 1 — PostgreSQL data corruption / accidental DELETE

1. Stop the backend container: `docker compose stop backend`.
2. Identify the most recent good backup in `/opt/roteirizador/backups/postgres/`.
3. Drop and recreate the database:
   ```
   docker compose exec postgres psql -U postgres -c "DROP DATABASE roteirizador;"
   docker compose exec postgres psql -U postgres -c "CREATE DATABASE roteirizador OWNER roteirizador;"
   ```
4. Restore from dump:
   ```
   cat /opt/roteirizador/backups/postgres/YYYY-MM-DD.dump | docker compose exec -T postgres pg_restore -U roteirizador -d roteirizador
   ```
5. Start backend: `docker compose start backend`.
6. Verify: `curl https://api.roteirizadorpro.com.br/health/db` returns 200.

### Scenario 2 — Backend container crash loop

1. Check logs: `docker compose logs backend --tail 200`.
2. Common causes: bad `.env` after a change, DB unreachable, port conflict.
3. Roll back to previous image: `git checkout <previous-tag> && docker compose up -d --build backend`.
4. If rollback succeeds, investigate the breaking change before redeploying.

### Scenario 3 — Droplet destroyed / region outage

1. Provision a new droplet (8GB, Ubuntu 24.04, São Paulo region preferred, NYC3 fallback).
2. SSH in. Run the install procedure from `docs/INSTALL.md` end to end.
3. Restore Postgres from the most recent off-site backup (Spaces / external storage).
4. Restore secrets from the off-server vault (1Password / Bitwarden).
5. Update DNS: change `api.roteirizadorpro.com.br` A record to the new droplet IP. TTL was kept low (300s) precisely for this scenario.
6. Reissue Let's Encrypt cert (Certbot).
7. Verify all four M1 acceptance criteria pass on the new server.

**Estimated time:** 2–3 hours if backups are off-site and `INSTALL.md` is up to date.

### Scenario 4 — DNS provider outage

1. The site at `roteirizadorpro.com.br` (Vercel) and the API at `api.roteirizadorpro.com.br` (DO droplet) become unreachable.
2. There is nothing to do at the application level.
3. If the outage exceeds 4 hours, consider migrating DNS to a backup provider (Cloudflare or Route 53). Keep the registrar's login at hand.

### Scenario 5 — Vercel outage (landing only)

1. The API and app continue working (different host).
2. The landing page is unavailable for new sign-ups (download link is offline).
3. Vercel outages are typically short (< 1 hour). No active recovery needed.
4. Long outage: consider hosting a static fallback at `landing.roteirizadorpro.com.br` on the same droplet. Out of scope for M1/M2.

### Scenario 6 — Stripe outage

1. New paywall checkouts fail (no Pix `next_action.pix_display_qr_code` can be generated).
2. Existing active access passes are unaffected (subscription status is in our DB, not Stripe's).
3. Show users a friendly error: "Serviço de pagamento temporariamente indisponível. Tente novamente em instantes."
4. Webhook backlog: when Stripe recovers, queued events fire. Idempotency by `stripeEventId` in `webhook_events` (ADR-0030) ensures no duplicate activations.

### Scenario 7 — Secret leak (password, API key, JWT key)

1. **Identify what leaked.**
2. Rotate immediately:
   - **Postgres password:** Update in `.env`, restart Postgres + backend.
   - **JWT keys:** Generate new keypair. Existing tokens become invalid; users have to log in again. Acceptable cost for a leak.
   - **`STRIPE_SECRET_KEY`:** Rotate in Stripe Dashboard → Developers → API keys (revoke old, generate new), update `.env`, restart backend.
   - **`STRIPE_WEBHOOK_SECRET`:** Rotate in Stripe Dashboard → Developers → Webhooks → endpoint details (regenerate signing secret), update `.env`, restart backend.
   - **SSH key:** Add new key, remove old one from `authorized_keys`.
3. Scrub Git history if the leak was committed: `git filter-repo` + force-push.
4. Document the incident in a session log with timeline and lessons learned.

## Monitoring (Detection)

For M1, detection is informal:

- Eduardo and the client should bookmark `https://api.roteirizadorpro.com.br/health` and check if anything seems off.
- Eduardo will perform a smoke test daily during the first week.

For M2 and beyond, recommend (out of scope for the contract):

- Uptime monitoring: UptimeRobot (free tier) hitting `/health` every 5 minutes.
- Error tracking: Sentry (already in stack) for backend exceptions and Flutter crashes.
- Alert channel: WhatsApp or email to both partners.

## Tested? Documented?

| Procedure | Tested | Documented | Last Tested |
|---|---|---|---|
| Postgres restore from dump | ❌ | ✅ | (will run during Sprint 2) |
| Backend rollback | ❌ | ✅ | (will simulate during Sprint 2) |
| Droplet rebuild from scratch | ❌ | ✅ (via INSTALL.md) | (manual run during Sprint 2 if time) |
| DNS failover | ❌ | ✅ | (not tested in M1; document only) |
| Secret rotation | ❌ | ✅ | (not tested in M1) |

A procedure is only as good as the last time it was rehearsed. After M1 ships, schedule a quarterly DR drill (10 minutes minimum: restore a backup to a test environment, verify integrity).
