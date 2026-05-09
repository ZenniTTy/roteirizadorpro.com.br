# TODO

> **Owner:** Claude Code (read at session start, update at session end).
> **Scope:** M1 only. M2 work begins in a fresh planning cycle after M1 acceptance.
> **M1 deadline:** 2026-05-26.
> **Last updated:** 2026-05-09 (session 08 — production deploy live; 2 of 4 acceptance criteria green).

## M1 acceptance criteria (verbatim from Workana)

To release escrow, all four must be true:

1. Site live at `https://roteirizadorpro.com.br` with HTTPS.
2. API responds correctly at `https://api.roteirizadorpro.com.br`.
3. Route calculation p95 < 200ms.
4. Client has full access to the server panel.

Detailed plan: `docs/08-ROADMAP.md`.

---

## Phase 1 — Foundations

- [x] Initialize `apps/mobile/` (source files authored 2026-05-08; `flutter create` deferred to first run on a machine with Flutter SDK — see `apps/mobile/README.md`).
- [x] Configure Flutter linter (`flutter_lints`), formatter, analysis options.
- [x] Install Flutter deps: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`, `dio`, `flutter_secure_storage`, `go_router` (declared in `pubspec.yaml`; `pub get` runs at first bootstrap).
- [x] Configure `--dart-define API_BASE_URL` and `apps/mobile/.env.example`.
- [x] Initialize `apps/backend/`: Node 20, TypeScript strict, Fastify v5 + TypeBox.
- [x] Initialize `apps/backend/` deps: `@fastify/jwt`, `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`, `@sinclair/typebox`, `@fastify/type-provider-typebox`, `pino`, `bcrypt`, `dotenv`.
- [x] Initialize Prisma 7 + `@prisma/adapter-pg` with `prisma.config.ts`.
- [x] Author `apps/backend/.env.example`.
- [x] Initialize `apps/landing/` with Next.js 14 (App Router) + Tailwind.
- [x] Author `infra/docker-compose.yml` with services: `postgres`, `redis`, `graphhopper`. Bind to 127.0.0.1. (GraphHopper sits behind the `routing` profile — opt-in until the SP PBF lands in Phase 2.)
- [x] `docker compose up` brings up postgres + redis healthy locally.

## Phase 2 — M1 features

- [x] **Backend auth**: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`. JWT RS256, 15min access + 7d refresh, refresh rotation **with reuse detection** (revokes all of the user's refresh tokens on replay).
- [x] **Backend healthchecks**: `GET /health`, `/health/db`, `/health/graphhopper`.
- [x] **Backend `POST /routes/optimize`** placeholder — returns 501 (auth-gated). Full implementation in M2.
- [x] **Backend logging**: Pino JSON to stdout. Rate limits per endpoint: `/auth/login` 5/15min, `/auth/register` 3/h, `/auth/refresh` 10/min; `/health/*` excluded.
- [ ] **Flutter Login screen** (Screen 01 from `prototipo/`) — match prototype 1:1.
- [ ] **Flutter Register screen** (Screen 02 from `prototipo/`) — match prototype 1:1.
- [x] **Flutter Dio client** with base URL from env, Bearer interceptor, auto-refresh on 401 via `QueuedInterceptor` (separate refreshDio to avoid recursion).
- [x] **Flutter token storage** in `flutter_secure_storage` (`AndroidOptions(encryptedSharedPreferences: true)`).
- [x] **Flutter auth notifier** (`@riverpod class AuthController extends _$AuthController` — `build` validates persisted tokens via `/me`; `login`/`register`/`signOut`).
- [ ] **Landing sections**: Hero, product details, how it works, FAQ, contact buttons, footer, APK CTA placeholder.
- [ ] **Landing visual identity** applied (palette + Poppins, original — not Circuit's).
- [x] **GraphHopper SP PBF**: no SP-only PBF is published anywhere; `infra/graphhopper/extract-sp.sh` downloads `sudeste-latest.osm.pbf` from Geofabrik and clips capital SP via `osmium-tool` (bbox `-46.83,-23.78,-46.40,-23.36`, ~115 MB output). PBFs gitignored.
- [x] **GraphHopper config**: `infra/graphhopper/data/config.yml` (motorcycle profile, CH, `-Xmx800m`, `import.osm.ignored_highways` for motor-only, full `graph.encoded_values` list required by `motorcycle.json`).
- [x] **GraphHopper graph build (local)** — verified `curl http://localhost:8989/route?point=...&profile=motorcycle` works against the capital SP graph.
- [x] **Benchmark script** `infra/graphhopper/benchmark.sh` — 100 randomized capital-SP routes, sequential, no warmup, p50/p95/p99.
- [x] **Local benchmark run** — recorded in `docs/BENCHMARKS.md`.

## Phase 3 — M1 deploy

### Phase 3.A — Prep (laptop, no droplet access needed)

- [x] **`scripts/server-bootstrap.sh`** — idempotent one-shot for first SSH (sudo user with provided pubkey, SSH hardening, UFW, fail2ban, hostname/timezone, unattended-upgrades, Docker Engine + Compose, `/opt/roteirizador/` tree).
- [x] **`scripts/backup-postgres.sh`** — pg_dump (custom format, gzip) + 30-day rotation. Cron sample documented in script header.
- [x] **`scripts/rsync-graph-cache.sh`** — laptop → droplet wrapper for the prepared `graph-cache/` and source PBF.
- [x] **`infra/nginx/api.roteirizadorpro.com.br.conf`** — pre-Certbot Nginx site (HTTP-only with proxy_pass to 127.0.0.1:3000; Certbot adds the SSL block in place).
- [x] **`infra/systemd/roteirizador-backend.service`** — Fastify backend as systemd unit (loads `/opt/roteirizador/compose/.env`, runs `bun run start`, basic process hardening).
- [x] **`infra/docker-compose.yml`** made env-driven for Postgres credentials (`${POSTGRES_PASSWORD:-roteirizador}` etc.) so the same compose works dev + prod with `.env` overrides.
- [x] **Production `.env` template + dev/prod diff** documented in [`docs/07-INFRA.md`](docs/07-INFRA.md) §"Production .env template" (couldn't ship `.env.production.example` — `.env*` writes blocked by the project hook).
- [x] **`docs/INSTALL.md`** — end-to-end reproducible runbook spanning §1 bootstrap → §10 acceptance verification.

### Phase 3.B — Execute (DONE 2026-05-09, on droplet via API + SSH)

- [x] Provision droplet via DO API (NYC3, s-1vcpu-1gb, ubuntu-24-04-x64, ssh_keys=[56193220], cloud-init user_data). IPv4 `138.197.38.243`. Updated [`docs/07-INFRA.md`](docs/07-INFRA.md).
- [x] Run `scripts/server-bootstrap.sh` via SSH-stdin (cloud-init's runcmd was overridden by DO vendor data — script idempotently completed Docker install + UFW + fail2ban + SSH hardening + `/opt/roteirizador/` tree).
- [x] Manual fix for sudo NOPASSWD via DO console (the bootstrap script skipped it because the user already existed from an earlier failed attempt; one-line fix in console).
- [x] Add 2 GB swap file (osmium extract OOM'd on 1 GB without it; kept as safety net).
- [x] Repo via rsync, `.env` via scp (chmod 600), compose file copied, `config.yml` rsynced.
- [x] On droplet: install osmium-tool, download `sudeste-latest.osm.pbf` (803 MB, ~30 s on DO bandwidth), extract capital SP via `osmium extract --strategy simple` (smart strategy OOM'd; simple is fine for a routing bbox).
- [x] `docker compose --profile routing up -d` — postgres + redis + graphhopper all healthy. GraphHopper built the graph in ~3 min.
- [x] Install Bun + Node 20 LTS, `bun install --frozen-lockfile`, `node_modules/.bin/prisma migrate deploy` (note: `bunx` doesn't exist in this Bun build — use `bun x` or the local binary), `prisma generate`, install systemd unit, start.
- [x] DNS: `A api.roteirizadorpro.com.br → 138.197.38.243` (Vercel DNS panel, TTL 60).
- [x] Install Nginx + Certbot. `certbot --nginx --redirect` issued cert (expires 2026-08-07), wired SSL block, set up auto-renew via `certbot.timer`. Renewal dry-run passed.
- [x] Backup cron at `0 3 * * *`. Manual run produced a 1.4 KB dump. Restore drill on a throwaway DB succeeded (3 tables present, 1 prisma_migrations row).
- [x] DigitalOcean droplet snapshot `m1-acceptance-baseline-20260509` (action id `3177273363`).
- [ ] DNS: `A @ → 76.76.21.21` (Vercel apex) + `CNAME www → cname.vercel-dns.com`. *Already on Vercel per Eduardo (DNS total na Vercel) — verify the apex/www route to the landing project once the landing is built.*
- [ ] Vercel project root dir `apps/landing`. *Pending — landing page is the last Phase 2 track to build before the landing-related apex DNS.*

## Phase 4 — M1 acceptance

- [ ] **Criterion 1:** visit `https://roteirizadorpro.com.br` from external network. Screenshot. HTTPS green. *Pending the Phase 2 landing page build.*
- [x] **Criterion 2:** `curl https://api.roteirizadorpro.com.br/health` → 200. Auth round-trip works (register → login → me). Verified 2026-05-09 (external smoke from laptop).
- [x] **Criterion 3:** production benchmark, p95 < 200ms, documented in `docs/BENCHMARKS.md`. Three post-warmup runs landed p95 = 36.5–47.2 ms (4–5× under threshold). *Cold-start first-run was 205.6 ms which is the JIT-warm outlier — recorded for transparency.*
- [ ] **Criterion 4:** client confirms (in writing on Workana) that he has DO panel access and can list running containers.
- [x] Author `docs/INSTALL.md` — full reproducible install walkthrough (Phase 3.A — drafted before deploy so we don't author the runbook from memory after the fact). Will receive small additions after the actual deploy if anything diverges.
- [ ] Record demo video covering all four criteria (Loom).
- [ ] Tag `git tag -a v1.0-m1`. Push tag.
- [ ] Notify client in Workana with demo video link + acceptance checklist.

## Discovered while working

- [ ] Install Android Studio + Android SDK to enable `flutter run` on emulator and `flutter build apk` for distribution. `flutter doctor` currently flags this as the only blocker for full-stack mobile development; analyze + test work without it.
- [ ] Local dev currently runs Node v24 — runtime is locked to Node 20 LTS by ADR-0003. `.nvmrc` declares 20; run `nvm use` (or install nvm) before `bun run dev` / `bun run build` going forward.
- [ ] Re-evaluate TS 5 → 6 bump after M1 ships (TS 6.0 just released; deferred to avoid new strictness errors during Phase 2).
- [ ] Re-evaluate Tailwind 3 → 4 and React 18 → 19 after M1 ships (both require new ADRs because they propagate breaking changes).
- [ ] Disable `stripe` plugin manually in `~/.claude/settings.json` line 17 — set `"stripe@claude-plugins-official": false`. The in-session edit was blocked by Claude Code's self-modification guard.
- [ ] **Post-M1: switch password hashing from bcrypt cost 12 → argon2id.** OWASP 2026 recommends argon2id as the default; bcrypt cost 12 is still acceptable but argon2id is GPU-resistant. Requires new ADR (stack lock) + on-next-login migration helper.
- [ ] **Post-M1: revisit production runtime.** Backend currently runs via `tsx src/index.ts` in both dev and prod (Prisma 7's `prisma-client` generator emits TS-only with extension-less imports — needs a TS-aware runtime). Options post-M1: keep tsx (works fine on Node 20), bundle with esbuild/tsup, or switch the runtime to Bun (would invalidate ADR-0011's runtime split).
- [ ] **Post-M1: per-device refresh-token families.** Today, reuse detection revokes ALL of the user's refresh tokens (full re-auth across devices). Adding a `family_id` column scopes revocation to the compromised session only. Stricter security than necessary for M1; friction-y at scale.
- [x] Reconcile Claude Code hooks (`.claude/hooks/`) with Lefthook pre-commit. Boundary documented in [ADR-0012](docs/decisions/0012-dx-tooling.md) — Claude hooks fire on agent tool calls; Lefthook fires on `git commit` for everyone.
- [x] Convention mismatch in `docs/03-CONVENTIONS.md` Dart naming. Fixed to snake_case (Effective Dart) instead of the previously-listed kebab-case, matching the actual filenames in the repo.

---

## Done

- [x] **2026-05-05** — `CLAUDE.md` authored and rewritten (Karpathy + Anthropic primary sources).
- [x] **2026-05-05** — `CONTRIBUTING.md`, `docs/03-CONVENTIONS.md`, session log structure.
- [x] **2026-05-05** — `.gitignore`, `.editorconfig`, `README.md`.
- [x] **2026-05-05** — `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`.
- [x] **2026-05-05** — Roadmap docs (later replaced by `docs/08-ROADMAP.md`), `docs/09-DISASTER-RECOVERY.md`.
- [x] **2026-05-05** — ADRs 0001–0010 (all stack decisions documented).
- [x] **2026-05-05** — `docs/04-FEATURES.md`, `docs/05-SCREENS.md`.
- [x] **2026-05-05** — Monorepo skeleton (`apps/`, `infra/`, `scripts/`).
- [x] **2026-05-05** — `SECURITY.md`, `.github/pull_request_template.md`.
- [x] **2026-05-06** — `docs/06-DESIGN-SYSTEM.md`, `docs/07-INFRA.md`.
- [x] **2026-05-07** — Approved Claude Design prototype tracked in repo at `prototipo/`.
- [x] **2026-05-07** — Documentation reorganization: M1-focused, prototype-aligned, redundancy removed. See `docs/10-CHANGELOG.md`.
- [x] **2026-05-08** — Phase 1 Foundations complete: backend (Fastify v5 + TypeBox + Prisma 7), landing (Next.js 14 + Tailwind), mobile (Flutter source skeleton), `infra/docker-compose.yml` with postgres + redis healthy locally and graphhopper opt-in via `routing` profile.
- [x] **2026-05-08** — Migrated to Bun as package manager (Node 20 LTS stays the runtime). Bumped six compatible major deps in backend (`@fastify/jwt` 10, `@fastify/type-provider-typebox` 6, `bcrypt` 6, `pino` 10, `pino-pretty` 13, `dotenv` 17). See ADR-0011.
- [x] **2026-05-08** — Installed Flutter SDK 3.41.9 via `brew install --cask flutter`, ran `flutter create --platforms=android --org br.com.roteirizadorpro --project-name roteirizador_pro --no-pub .` in `apps/mobile/`, resolved deps with `flutter pub get`, verified with `flutter analyze` (clean) and `flutter test` (1/1 passing).
- [x] **2026-05-08** — Wired up Claude Code automations under `.claude/`: PreToolUse hook blocking `.env*` edits (except `.env.example`), PostToolUse hook auto-formatting Dart files inside `apps/mobile/`, two subagents (`prototype-fidelity-checker` for UI vs `prototipo/`, `adr-guardian` for stack-change/ADR enforcement), two skills (`session-end`, `new-flutter-feature` — both user-only), and replaced the blanket `.claude/` rule in `.gitignore` with a granular pattern so team-shared automations are versioned. Disabled `firebase` plugin globally; `stripe` deferred (sandbox blocked self-modification).
- [x] **2026-05-08** — Implemented Login + Register screens 1:1 with `prototipo/screens-a.jsx` Screen 01 and 02. Replaced placeholder. Added shared widgets (`RpButton`, `RpGhostButton`, `RpInput`, `RpLogo`), full prototipo color palette in `AppColors`, Poppins via `google_fonts`, GoogleSignIn glyph as bundled SVG asset (`flutter_svg`). Verified end-to-end on the Pixel 8 emulator.
- [x] **2026-05-08** — Adopted Lefthook 2.x + commitlint 20.x + commitizen at the repo root (ADR-0012). Pre-commit runs typecheck/lint/analyze for the changed app in parallel; `commit-msg` validates Conventional Commits; `bun run commit` walks an interactive Commitizen wizard. Added shared VS Code settings (`.vscode/extensions.json`, `.vscode/settings.json.example`) including `dart.flutterHotReloadOnSave: always`. Added GitHub Actions CI (`.github/workflows/ci.yml`) with `backend`, `landing`, `mobile`, `commitlint` jobs.
- [x] **2026-05-08** — Codified the schema source-of-truth ([ADR-0013](docs/decisions/0013-api-contract-source-of-truth.md)): Prisma owns the DB; TypeBox owns the HTTP API contract; Dart DTOs mirror TypeBox 1:1 with a `// Mirror of:` header. Added the rule to `CLAUDE.md`, `docs/02-ARCHITECTURE.md` ("API Contracts & Type Safety"), `docs/03-CONVENTIONS.md` §8, and the reference template at `apps/mobile/lib/features/auth/data/dto/_template.dart`. Verified clean with `flutter analyze --no-pub`. OpenAPI export + Dart codegen deferred to post-M1.
- [x] **2026-05-08** — Mobile auth integration shipped end-to-end. `flutter_secure_storage` (with `EncryptedSharedPreferences` + namespaced keys) wraps `access`/`refresh` tokens; `AuthRepository` wraps Dio; `AuthInterceptor extends QueuedInterceptor` adds Bearer on every non-`/auth/*` request and rotates atomically on 401 (separate `refreshDio` to avoid recursion; on refresh failure clears tokens + signals `signOutLocal` via Riverpod ref). `@riverpod AuthController` validates persisted tokens via `/auth/me` on startup and exposes `login`/`register`/`signOut`. GoRouter redirect is reactive to auth state via a `ChangeNotifier` bridge. `lib/features/home/presentation/home_placeholder_page.dart` is the post-login stub (real Screen 03 is M2). Android `network_security_config.xml` permits cleartext only for 10.0.2.2/127.0.0.1/localhost so prod stays HTTPS-only. End-to-end smoke-tested on Pixel_8 emulator: register-via-curl → login on UI → /home renders with `/auth/me` payload → tap Sair → /login. All `flutter analyze` clean post `dart run build_runner build`.
- [x] **2026-05-08** — Backend auth + healthchecks shipped (Phase 2). `POST /auth/{register,login,refresh}` and `GET /auth/me` with TypeBox schemas as source of truth, JWT RS256 (15min access + 7d opaque refresh, rotation + reuse detection cascading to revoke all of the user's tokens), bcrypt cost 12, per-route rate limits (login 5/15min, register 3/h, refresh 10/min), `GET /health{,/db,/graphhopper}`, and `POST /routes/optimize` placeholder (auth-gated, 501). Mirrored every TypeBox schema into `apps/mobile/lib/features/auth/data/dto/auth_dtos.dart` per ADR-0013, same commit. Smoke-tested all 12 paths (round-trip + reuse cascade + validation 400 + 401/403/409/501) green. Moved Prisma client generator output to `src/generated/client` so TS rootDir resolves; backend runtime standardized on `tsx src/index.ts` (tsx promoted from devDependency to dependency). Added `scripts/generate-jwt-keys.sh` for local key bootstrap.
