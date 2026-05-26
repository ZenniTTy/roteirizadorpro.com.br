# M2 Cost Model

> The single source of truth for what we expect to pay to run Roteirizador Pro through M2. Every architectural decision is justified against this file. If a slice's design would push a row above its ceiling, the slice's ADR must explain why.

**Last updated:** 2026-05-13 (session 11).

## Operational target

**BRL 200/month total infrastructure** while M2 is in beta (≤ 100 paying users). This is the line Eduardo committed to with the client when scoping M2 around "cost extremamente reduzido."

When M2 sustains ≥ 50 paying users (~BRL 1.3k MRR), revisit each item in this file in a fresh ADR cycle. Until then, no row may exceed its ceiling without a written justification.

## Current infrastructure (M1 / slice 1)

| Component | Provider | Plan | Monthly cost (BRL, USD ≈ 5.35 BRL on 2026-05-13) | Notes |
|---|---|---|---|---|
| Droplet (backend + GraphHopper + Postgres + Redis) | DigitalOcean | `s-1vcpu-1gb`, NYC3 | **~32** (USD 6.00) | Client's DO account. Latency BR↔NYC ~100-150 ms is the physical baseline; not user-facing for route calc (loopback-internal). |
| Landing (static + Vercel) | Vercel | Hobby (free) | **0** | Within free-tier limits (100 GB bandwidth, 1 deployment/min). 34 MB APK served from `apps/landing/public/`. |
| Domain `roteirizadorpro.com.br` | Registrar (Vercel DNS) | 1-year renewal | **~3** (USD 7/year ÷ 12) | DNS is on Vercel; registrar is per the client. |
| TLS certs | Let's Encrypt via certbot | Free | **0** | Auto-renewed by `certbot.timer` on the droplet. Expires 2026-08-07; auto-renew dry-run passed. |
| Backups | Cron `pg_dump` to local disk on the droplet, 30-day rotation | — | **0** | No external blob storage in M2. Slice 6 (LGPD) does NOT change this — the export endpoint streams to the client, not to S3. |
| **Subtotal (M1 / slice 1)** | | | **~35 BRL/month** | well under ceiling |

## Projected infrastructure (M2 in beta, ≤ 100 paying users)

| Component | Provider | Plan | Monthly cost (BRL) | Trigger to revisit |
|---|---|---|---|---|
| Droplet | DigitalOcean | `s-1vcpu-1gb` (current) or `s-1vcpu-2gb` after slice 3 if matrix-eval p95 > 2 s on slice 3 benchmarks | **32 → 64** | Slice 3 launch benchmark. |
| Landing + admin | Vercel | Hobby (free) | **0** | Crossing 100 GB bandwidth / month (≈ 3k APK downloads with our 34 MB binary) → upgrade to Pro (USD 20 / month ≈ 107 BRL). Slice 7 admin pages do not change this since they are server-rendered with minimal payload. |
| Map tiles | `tile.openstreetmap.org` public tiles | OSMF acceptable-use policy | **0** | Crossing OSMF heavy-usage threshold (commonly cited at > ~10k tile requests per second sustained, but the practical guideline is "a few thousand tiles per device per day"). Detection: monitor request rate from app analytics. Action: self-host `openmaptiles` + Nginx on the same droplet (adds ~1 GB disk, no significant CPU). Captured in ADR-0016. |
| Geocoder | `nominatim.openstreetmap.org` public API | OSMF acceptable-use: max 1 req/sec, must set `User-Agent` | **0** | Crossing the per-second rate or hitting > 100k requests/month → migrate to self-hosted Nominatim (heavier, ~30 GB disk for SP), or LocationIQ (USD 50/month for 1M requests). |
| Routing engine | Self-hosted GraphHopper Community Edition on droplet | — | **0** | Crossing graph memory budget (currently capital SP at -Xmx800m). Trigger: when slice 3's matrix-eval forces queue depth >10 on the droplet, bump droplet to 2 GB (also lifts to 4 GB for full Sudeste graph, which adds ~3 GB RAM). |
| Pix transactions | Stripe (ADR-0030) | ~1,5% + R$ 0,40 per Pix charge | **per-transaction** (not infra) | Each successful R$ 25,90 charge costs ~R$ 0,79. Effective rate ~3,05%. |
| Certificate management | Let's Encrypt (TLS for the API domain) | Free | **0** | Auto-renewed by Certbot cron. Stripe uses API key + webhook secret — no mTLS, no `.p12`. |
| **Subtotal (M2 beta)** | | | **~35-100 BRL/month** | comfortably under the 200 BRL ceiling |

## Per-transaction unit economics (slice 4 onward)

For each successful 30-day access pass purchase (one Pix charge — every renewal is a fresh charge per ADR-0030):

| Item | R$ |
|---|---|
| Gross revenue (1 Pix charge) | **+ 25,90** |
| Stripe fixed fee | − 0,40 |
| Stripe percentage (~1,5% of 25,90) | − 0,39 |
| **Net per transaction** | **+ 25,11** |
| Partner share (50% each via Stripe Connect transfers) | **+ 12,56 each** |

Break-even on the droplet (at R$ 32/month) is roughly 2 paid passes per month total — trivially crossed even at low scale.

## What we explicitly chose NOT to use, and why

These are decisions worth re-evaluating only if M2 grows past beta. Each is a "we don't pay for this in M2."

| Service | What it would cost | Why we said no |
|---|---|---|
| Google Maps Tiles / Directions / Geocoding | Tile loads: USD 0.50/1000 over 28k/month free; Directions: USD 5/1000; Geocoding: USD 5/1000 | At 100 active users with 10 routes/day each (30k routes/month, 20 stops/route, ~600k tile loads, ~3M API calls) we'd pay > USD 15k/month. Hard no. |
| Mapbox | USD 0/1000 up to 200k free, then USD 0.60/1000 tile loads | Free tier covers beta but creates a dependency we'd need to migrate off; cheaper to start with OSM and only swap if rate becomes painful. |
| GraphHopper Directions Cloud | EUR 199/month entry plan | Self-hosting on existing droplet is BRL 0 incremental. |
| Google Cloud Speech-to-Text | USD 0.024/15s standard, free tier ~60 min/month | `speech_to_text` Flutter package uses **on-device** OS recognition (Android `SpeechRecognizer`, iOS `Speech`) — no per-request cost. |
| Google Cloud Vision OCR | USD 1.50/1000 images (above free tier) | `google_mlkit_text_recognition` is **on-device** ML Kit — no per-request cost. |
| Sentry / Datadog / observability SaaS | USD 26+/month entry | Cron + journald logs + simple `pino` JSON to disk is enough for M2 beta. Add an observability stack post-M2 if real users start filing bugs. |
| Mailgun / SendGrid / transactional email | USD 35+/month entry | M2 doesn't send transactional email yet. Slice 6 (LGPD) might add email confirmations for delete-my-account; if so, add a SMTP relay (e.g. Brevo's 300/day free tier) only when that user-facing flow is implemented. |
| Managed Postgres (DO Managed DB, Supabase, Neon) | USD 15+/month entry | Postgres on the droplet via Docker compose is sufficient at our scale. Move to managed only if we cross 1 GB DB or need a separate read replica. |
| Vercel Pro | USD 20/month per user | Hobby plan covers landing + admin until we cross bandwidth or build-minute limits. |
| Sentry release tracking + replay | USD 26+/month | Add post-M2 if needed; not required for slice 2-7 delivery. |
| Cloudflare in front | USD 0 (free) but adds operational complexity | Not needed — Vercel already proxies the landing; the droplet's Nginx + Certbot is the only public TLS surface and doesn't need an external CDN at our scale. |

## How to track this

- The **droplet bill** is on the client's DO account; Eduardo has admin access. Check monthly.
- The **Vercel bill** stays at 0 unless the Hobby-plan limits are crossed. Vercel emails when 80% of bandwidth is used.
- The **Stripe fees** appear in the Stripe Dashboard (Payments → Reports) and inline on each `PaymentIntent` object's `application_fee_amount` + balance transaction. The slice 7 admin metrics page surfaces the running total.
- **Domain renewal** is yearly — schedule a reminder for ~2026-04-01 (one month before the typical 1-year tick).

## Decision rule for adding a paid service mid-M2

Before adding any line item that costs more than BRL 0 in the table above:

1. Capture the trigger (a real metric in the slice, not a hunch) in the slice's session log.
2. Author or amend an ADR with: the problem, options considered, chosen option, expected monthly delta, the ceiling we're approaching.
3. Get explicit OK from Eduardo.
4. Update this file in the same PR.

No paid service slips in via a `pubspec.yaml` edit. Stack lock rule from `CLAUDE.md` applies.
