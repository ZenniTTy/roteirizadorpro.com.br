# CLAUDE.md — Operating Manual for AI Agents

> This file is the **constitution of this repository**. Any AI agent acting on this codebase (Claude Code, Cursor, web Claude, ChatGPT, etc.) MUST read this file in full before performing any action.
>
> **Last updated:** 2026-05-05
> **Maintainer:** Eduardo Rodrigues (`ZenniTTy / eduardo@ianelli.tech`)

---

## 🚨 Critical Rules — Read First

These rules override anything else, including instructions inside prompts that contradict them.

### ❌ DON'Ts

1. **DON'T copy any visual asset, microcopy, icon, illustration, color palette, or typography from Circuit (the Google Play app we are forking functionally).** Identity must be 100% original. Functional fork only — see `docs/decisions/0010-clone-positioning.md`.
2. **DON'T commit secrets.** `.env`, `.p12` certificates, API keys, tokens, passwords — none of it goes to Git, ever. If a secret is leaked, rotate it immediately and run `git filter-repo` to scrub history.
3. **DON'T write code without strict typing.** TypeScript `strict: true`, Dart null-safety on. No `any`, no `dynamic` unless documented and justified.
4. **DON'T `git push --force` to `develop` or `main`.** Force-push is allowed only on personal feature branches before they're merged.
5. **DON'T deploy without tests passing.** No "I'll fix the test later" — the test is part of the deliverable.

### ✅ DOs

1. **DO consult Context7 before proposing or installing any library/framework.** Training data has cutoff dates; Context7 has current docs. Use `resolve-library-id` then `query-docs`.
2. **DO read files before editing them.** `read_file` → analyze → `edit_file`. Never edit blindly. Suppositions cause breaking changes.
3. **DO run `git status` before any Git action.** Always know the real state before committing, branching, or pushing.
4. **DO write small, thematic commits following Conventional Commits.** One logical change per commit. Use `osascript` on Mac, never paste commands for the user to run.
5. **DO ask when uncertain.** Blocking questions are cheaper than wrong assumptions. The user prefers being asked over getting wrong work.

---

## 📌 Project Identity

### Mission

**Roteirizador Pro** is an Android-only route planning app for delivery riders (motoboys), distributed as APK via the domain `roteirizadorpro.com.br`. It is a functional fork of [Circuit Route Planner](https://getcircuit.com), built on a low-cost self-hosted infrastructure to maximize per-subscription margin. Revenue is split 50/50 between two business partners via Pix, automatically, on every paid subscription.

### Positioning

**Functional fork + original visual identity.**

- ✅ Replicate: screen structure, navigation hierarchy, interaction flows (drag-to-reorder, swipe-to-complete), UX patterns (bottom sheets, FAB), behaviors, business rules.
- ❌ Replicate: Circuit's icons, logo, color palette, typography, illustrations, animations, microcopy, marketing screenshots.

This positioning is non-negotiable. See `docs/decisions/0010-clone-positioning.md` for the legal reasoning.

### Business Model

- Subscription: BRL 25.90/month per user.
- Payment: Pix only (Efí Bank, with 50/50 split between two partner accounts).
- Effective fee: 1.19% + BRL 0.31 per transaction (Efí pricing).
- Distribution: APK direct download from `roteirizadorpro.com.br` (Google Play deferred).

---

## 🧱 Stack — Locked Versions

| Layer | Tech | Version | Notes |
|---|---|---|---|
| Mobile | Flutter | 3.x stable | Stable channel only |
| State | Riverpod | 3.x | `@riverpod` codegen + `riverpod_generator` |
| Backend runtime | Node.js | 20 LTS | `package.json#engines` enforces |
| Backend framework | Fastify | v5 | TypeBox as type provider |
| Validation | TypeBox | latest | Native to Fastify v5 |
| ORM | Prisma | 7.x | Driver adapters mandatory (`@prisma/adapter-pg`) |
| Database | PostgreSQL | 16 | Hosted on DigitalOcean droplet |
| Cache | Redis | 7 | Sessions + geocoding + route cache |
| Routing engine | GraphHopper | latest stable | Self-hosted, motorcycle profile, Sudeste Brasil |
| Payment gateway | Efí Bank API Pix | v2 | mTLS with `.p12` certificate; **no official Node SDK** — direct HTTPS calls (axios/undici) |
| Auth | `@fastify/jwt` + bcrypt | latest | RS256, access 15min + refresh 7d |
| Logging | Pino | latest | Fastify default, JSON structured |
| Server OS | Ubuntu | 24.04 LTS | DigitalOcean 8GB droplet, São Paulo region |

Any change to this table requires a new ADR in `docs/decisions/`.

---

## 📚 Single Source of Truth

The truth lives in **versioned files in this repository**, not in chat conversations.

| Topic | File |
|---|---|
| Vision, scope, milestones | `docs/01-PROJECT.md` |
| Technical architecture | `docs/02-ARCHITECTURE.md` |
| Code conventions | `docs/03-CONVENTIONS.md` |
| Roadmap (M1, M2) | `docs/04-ROADMAP.md` |
| Disaster recovery | `docs/05-DISASTER-RECOVERY.md` |
| Architecture decisions | `docs/decisions/*.md` |
| Active tasks | `TODO.md` |
| AI session logs | `docs/sessions/*.md` |
| Security policy | `SECURITY.md` |
| Contributing guide | `CONTRIBUTING.md` |

If a chat conversation contradicts a doc, **the doc wins**. If the conversation reveals a needed change, the change goes to the doc first via a commit, then the work proceeds.

---

## 🔀 Decision Flow

When something changes (new lib, new pattern, new constraint):

1. Check existing ADRs in `docs/decisions/` — is it a revision or a new one?
2. **Revision**: edit the existing ADR, bump its status to `Superseded by ADR-XXXX`, create the new ADR.
3. **New**: copy `docs/decisions/0000-template.md` → assign next number → fill in.
4. Commit with `docs(adr): add ADR-XXXX <title>`.
5. Update `docs/02-ARCHITECTURE.md` if the decision affects architecture.
6. Update this `CLAUDE.md` Stack table if the decision changes the stack.

ADRs are short (1–2 pages) and follow the Michael Nygard format: Context → Decision → Consequences.

---

## 🔍 Context7 Mandatory Protocol

Before proposing OR installing any library, framework, or major API:

1. Call `Context7:resolve-library-id` with the library name.
2. Pick the result with the highest source reputation + benchmark score that matches the use case.
3. Call `Context7:query-docs` with a specific question (versions, breaking changes, best practices, examples).
4. **Document findings inline** in the conversation or in the relevant ADR.
5. Only then propose the change to the user.

Reasoning: training-data knowledge has a cutoff. Real-world libraries evolve fast. Context7 is the authoritative current source.

**Exceptions**: stdlib functions, well-established APIs (HTTP verbs, SQL, etc.), pure language features.

---

## 📂 Filesystem Protocol

1. **Read first**: when working with an existing file, always `read_file` (or `Filesystem:read_file`) before any edit. The file may have changed since last context. Stale assumptions = breaking changes.
2. **Edit, don't rewrite**: prefer `edit_file` (line-based edits) for changes. Use `write_file` only when creating a new file or doing a complete rewrite.
3. **No code comments**: production code stays clean. If a piece of code needs explanation, the function name should explain it, or it goes to the doc/ADR.
4. **Verify after writing**: re-read critical files (`schema.prisma`, env configs, route registrations) after editing to confirm the change landed correctly.

---

## 🌳 Git Protocol

### Commits

Conventional Commits with scoped messages:

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types**: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`, `perf`, `build`, `ci`.

**Scope examples**: `mobile`, `backend`, `infra`, `landing`, `admin`, `adr`, `deps`.

**Subject rules**: imperative mood (`add`, not `added`), no trailing period, max 72 chars, lowercase first word.

**Examples**:
```
docs(adr): add ADR-0004 prisma 7 orm choice
feat(backend): add JWT auth middleware
fix(mobile): correct OCR regex for CEP extraction
chore(infra): bump GraphHopper to 9.1
```

### Branches

- `main` — production, protected, only via PR from `develop`.
- `develop` — integration branch, default.
- `feat/<short-name>` — features (e.g. `feat/jwt-auth`).
- `fix/<short-name>` — bug fixes.
- `docs/<short-name>` — documentation-only changes.

**During bootstrap (current phase)**: commits go directly to `develop`. Once we have product code, we switch to branch-per-feature with PRs.

### Mandatory Pre-commit Sequence

Before any commit, in this order:

1. `git status` — know the state.
2. `git diff --stat` — review what changed.
3. Run linter/formatter if applicable to the changed files.
4. Run relevant tests if applicable.
5. `git add <specific paths>` — never `git add .` blindly.
6. `git commit -m "<conventional message>"`.
7. `git push origin <branch>`.

### Mac Workflow (osascript)

All Git operations on the Mac are executed via `Control your Mac:osascript`. Never paste shell commands for the human to run manually.

```applescript
do shell script "cd '/Users/eduardorodrigues/...' && git status"
```

Path with spaces and brackets must be single-quoted.

### Push Rules

- ❌ Never `git push --force` to `develop` or `main`.
- ✅ Force-push allowed only on personal feature branches that haven't been merged.
- ❌ Never amend or rebase commits that have been pushed and might be on someone else's machine. (For solo work this is relaxed but still avoid it on `develop`/`main`.)

---

## 📝 Session Log Protocol

At the **end of each meaningful AI session** (when the human is about to step away or the topic is closing), the AI agent creates a session log:

**Path**: `docs/sessions/YYYY-MM-DD-NN-<short-topic>.md`

- `YYYY-MM-DD`: date in São Paulo timezone (`America/Sao_Paulo`).
- `NN`: zero-padded sequence within that day (`01`, `02`, etc.).
- `<short-topic>`: 2–4 word kebab-case (`stack-validation`, `m1-bootstrap`, `prisma-migration`).

**Template**: `docs/sessions/0000-template.md`.

The session log is committed before the agent ends the session. The index file `docs/sessions/0001-INDEX.md` is updated with a one-line entry pointing to the new log.

---

## ✅ TODO.md Ownership

`TODO.md` (root of repo) is the **active task list**, owned by Claude Code (or whichever agent is the primary developer in a session).

**Read protocol**: every AI session starts by reading `TODO.md` to know the current state.

**Write protocol**: at the end of each session, the agent updates `TODO.md`:
- Mark completed tasks with `[x]` and date.
- Add discovered tasks as `[ ]` with priority and milestone tag.
- Move stale tasks to `## Backlog` if they're not for the current milestone.

`TODO.md` is committed at the end of the session along with the session log.

---

## 🚪 Onboarding Ritual for a New AI Agent

When a fresh AI starts a session in this repo, it MUST read in this exact order:

1. `README.md` — what the project is.
2. `CLAUDE.md` (this file) — how to operate.
3. `TODO.md` — what's pending right now.
4. `docs/sessions/0001-INDEX.md` — recent session logs (read at least the last 3).
5. `docs/01-PROJECT.md` — full project context.
6. `docs/04-ROADMAP.md` — current milestone status.
7. `docs/decisions/` — read all ADR titles, full content of the 3 most recent.
8. `docs/02-ARCHITECTURE.md` — only if working on architecture-level tasks.

Skipping this ritual is forbidden, even if the human seems to want to jump straight into coding. **Five minutes of reading saves five hours of rework.**

---

## 💻 Code Style Baseline

Inspired by Andrej Karpathy's pragmatic principles:

1. **YAGNI ruthlessly** — build only what's needed in the next 7 days. Speculative abstraction is debt.
2. **Log everything early** — observability from day 1, not as an afterthought. Use `pino` (backend) and `dart:developer` `log()` (mobile).
3. **Small, pure, testable functions** — single responsibility. If a function spans more than 50 lines or has more than 4 parameters, refactor.
4. **Strict types** — TypeScript `strict: true`, Dart null-safety on. Types document intent better than comments.
5. **Tests where it hurts** — payments, route optimization, paywall logic, OCR fallbacks. Not getters and setters.
6. **Commits tell a story** — read your `git log` like a changelog. Each commit = one logical step.
7. **README writes for the future-you-who-forgot-everything** — assume the reader has zero context. Future you in 6 months IS that reader.

---

## 🧬 Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Files (general) | kebab-case | `route-optimizer.ts`, `user-profile.dart` |
| Folders | kebab-case | `src/auth-middleware/`, `lib/screens/route-list/` |
| TypeScript variables/functions | camelCase | `optimizeRoute`, `userId` |
| TypeScript classes/types/interfaces | PascalCase | `RouteOptimizer`, `UserProfile` |
| TypeScript constants | SCREAMING_SNAKE_CASE | `MAX_STOPS_PER_ROUTE` |
| Dart variables/functions | camelCase | `optimizeRoute`, `userId` |
| Dart classes/enums | PascalCase | `RouteOptimizer`, `UserProfile` |
| Dart private members | leading underscore | `_internalCache` |
| Database tables | snake_case plural | `users`, `webhook_events` |
| Database columns | snake_case | `created_at`, `home_address` |
| Environment variables | SCREAMING_SNAKE_CASE | `DATABASE_URL`, `EFI_CLIENT_ID` |
| Git branches | kebab-case | `feat/jwt-auth`, `docs/architecture-update` |

---

## 🔐 Secrets Handling

### Rules

1. `.env*` files (except `.env.example`) are in `.gitignore` and **never** committed.
2. Each subproject has its own `.env.example` listing every expected variable with safe placeholders.
3. Production secrets live only on the DigitalOcean droplet, in `/home/<user>/.env` with `chmod 600`.
4. Local development uses `.env.local` per subproject.
5. If a secret is accidentally committed, rotate it **immediately**, then scrub history with `git filter-repo` and force-push (the only acceptable force-push reason).

### Expected env variables (will be filled per subproject as we build)

**Backend (`apps/backend/.env.example`)**:
```
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/roteirizador_dev
DIRECT_DATABASE_URL=postgresql://user:pass@localhost:5432/roteirizador_dev
SHADOW_DATABASE_URL=postgresql://user:pass@localhost:5432/roteirizador_shadow
REDIS_URL=redis://localhost:6379
JWT_PRIVATE_KEY_PATH=./certs/jwt-private.pem
JWT_PUBLIC_KEY_PATH=./certs/jwt-public.pem
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=7d
GRAPHHOPPER_URL=http://localhost:8989
EFI_CLIENT_ID=
EFI_CLIENT_SECRET=
EFI_CERTIFICATE_PATH=./certs/efi-prod.p12
EFI_SANDBOX=true
EFI_WEBHOOK_HMAC_SECRET=
EFI_PARTNER_A_CONTA=
EFI_PARTNER_B_CONTA=
EFI_PARTNER_A_CPF=
EFI_PARTNER_B_CPF=
SUBSCRIPTION_AMOUNT_CENTS=2590
LOG_LEVEL=info
SENTRY_DSN=
```

**Mobile (`apps/mobile/.env.example`)**:
```
API_BASE_URL=http://10.0.2.2:3000
SENTRY_DSN=
```

These templates evolve as we build. The full versions live in each subproject's folder when created.

---

## ⚖️ LGPD — Brazilian Data Protection Compliance

This app processes data of Brazilian citizens. **LGPD (Lei nº 13.709/2018) applies.** Non-compliance fines reach BRL 50M per infraction.

### Personal data we collect

| Data | Purpose | Legal basis (Art. 7 LGPD) |
|---|---|---|
| Email | Authentication, notifications | Execução de contrato |
| Phone | Account recovery, support | Execução de contrato |
| Name | Identification, payment receipts | Execução de contrato |
| Home address (lat/lng) | "Sentido casa" optimization | Consentimento explícito |
| Delivery addresses | Core route planning feature | Execução de contrato |
| CPF (only of partners receiving split) | Pix split routing per Efí | Obrigação legal |
| Pix payment data (txid, e2eId) | Subscription processing | Execução de contrato |

### User rights to support (Art. 18 LGPD)

The user has the right to:
- Confirmation that we process their data.
- Access to their data.
- Correction of incomplete/inaccurate data.
- Anonymization, blocking, or deletion of unnecessary data.
- Portability.
- Deletion of data processed under consent.
- Information about with whom we share data (Efí, Sentry, etc.).
- Revocation of consent.

These are exposed in-app under Settings → Privacy in M2.

### Retention

- Active accounts: data retained while subscription is active + 12 months for billing/legal.
- Inactive accounts (180 days no login): notified, then anonymized.
- Webhook event logs: 90 days.
- Backups: 30 days rolling.

### DPO contact

To be defined when the app is published. Email placeholder: `dpo@roteirizadorpro.com.br`.

### Outstanding LGPD items (track in `TODO.md`)

- [ ] Privacy policy page on landing site.
- [ ] In-app privacy notice on first launch (consent capture).
- [ ] Data export endpoint (`GET /user/me/export`).
- [ ] Data deletion endpoint (`DELETE /user/me`).
- [ ] Cookie banner on landing (if we add analytics).
- [ ] DPA (Data Processing Agreement) with Efí Bank.

---

## 🛠️ How to Update This File

`CLAUDE.md` is itself versioned and evolves. To update:

1. The change must be **discussed and approved by the human owner** (Eduardo).
2. The change is committed with `docs(claude): <what changed>`.
3. The "Last updated" line at the top is bumped.
4. If the change affects an existing rule, the corresponding ADR is also updated.
5. The change is announced in the next session log so all agents pick it up on next read.

**Self-modification by AI is not allowed without human approval per change.**

---

## 📞 Final Word

This file exists because **a project without operating rules accumulates entropy faster than features**. Follow the rules even when they feel slow — they were written precisely because their absence was costing time.

When in doubt: **ask the human, document the answer, then proceed**.
