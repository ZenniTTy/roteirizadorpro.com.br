# Spec — Docs cleanup & realignment for Flutter dev start

> **Date:** 2026-05-07
> **Author:** Claude Code (with Eduardo)
> **Status:** Awaiting user approval before implementation plan

---

## Context

Roteirizador Pro has ~30 docs/markdown files but **zero lines of code**. The project is a fork of Spoke/Circuit with original visual identity, sold to a Workana client as M1 (BRL 2,000) + M2 (BRL 2,000), proposal accepted **2026-04-26** with a **30-day delivery window** (M1 deadline ≈ **2026-05-26** — 19 days remaining as of 2026-05-07).

A complete UI prototype was generated in Claude Design and **approved by the client** (lives in `prototipo/` — 19 screens, React/HTML, design tokens including a `neon` color not in current docs).

**Server titularity is the client's** per the Workana proposal verbatim ("firewall e segurança total sob sua titularidade"). The client has a temporary card limitation and cannot afford the contracted 8GB droplet right now — he wants to **validate the entire M1 flow on a $6/month 1GB droplet first**, then provision the 8GB and resize after escrow release. This is the agreed workaround.

Vercel project exists.

The previous TODO.md "local-first / mobile-first" rewrite contradicts the Workana M1 contract and the client's approved scope. The user (Eduardo) decided that M2 will be **front-only against mocks** — this is a **scope reduction vs the original Workana proposal** and requires explicit renegotiation with the client in writing before M2 delivery.

The user wants to start coding Flutter, but the docs are a blocker: ambiguous, duplicated, partially obsolete, and out of sync with the approved prototype, the actual contract terms, and the 1GB workaround.

## Goal

**Single focus: deliver M1.** M2 is post-M1 work — scope and approach will be reconfirmed with the client after M1 acceptance. This spec keeps M2-related content at the level of "what was contracted" (preserved in FEATURES.md, ADRs, prototype) without planning the M2 implementation now.

Reorganize the documentation so that:

1. **Anything obsolete or ambiguous is deleted** — no contradictions between files.
2. **Business rules and Spoke/Circuit feature map are preserved** — these are the high-value content the user explicitly called out and will be needed for M2 conversations later.
3. **Roadmap is rewritten as M1-only** with these parameters:
   - **M1 deadline:** 2026-05-26 (30 days from acceptance on 2026-04-26 — 19 days remaining as of 2026-05-07).
   - **Server:** 1GB droplet (workaround agreed with client because of his card limitation). SP-only GraphHopper graph. Resize + Sudeste reimport happens **after M1 escrow release**.
   - **Mobile in M1:** only Login + Register screens (the only auth scope in the contract).
   - **M2:** referenced as "post-M1 — scope to be reconfirmed with client" — no implementation planning here.
4. **Prototype is the canonical source** for visual identity, screens, gestures, and flows. The 19 prototype screens are documented as the approved UI; M1 implements 2 of them, M2 will address the rest in a future planning cycle.
5. **Server titularity stays with the client.** DigitalOcean account is the client's; Eduardo has admin access. INFRA doc reflects this.
6. **The repo is ready for `flutter create apps/mobile/`** with auth-only scope as the next concrete action.

## Non-goals

- Writing application code in this pass. This spec is documentation reorganization only.
- Re-deciding stack choices. ADRs 0001–0010 stay as-is.
- Testing the prototype itself — it's already approved.
- Renumbering ADRs.
- Modifying `prototipo/` content (it's the source of truth, not output).

---

## Inventory of current docs (30 files)

### Root (8)
- `README.md` — Project intro
- `CLAUDE.md` — AI agent operating manual
- `agents.md` — **Duplicates CLAUDE.md** (different file, different rules)
- `CONTRIBUTING.md` — Git workflow (mentions `osascript` for Mac — irrelevant in Claude Code)
- `SECURITY.md` — Security policy
- `CODE_OF_CONDUCT.md` — **Solo project + 1 client = no purpose**
- `TODO.md` — 326 lines, mixes blockers/milestones/checklists
- `logo.png` — 1.4MB, untracked, doesn't belong in root

### docs/ (11)
- `01-PROJECT.md` — Vision, scope, milestones
- `02-ARCHITECTURE.md` — Stack, flows, schemas, contracts
- `03-CONVENTIONS.md` — Naming, code style
- `04-ROADMAP-M1.md` — **Conflicts with TODO.md mobile-first rewrite**
- `04-ROADMAP-M2.md` — Same conflict
- `06-DISASTER-RECOVERY.md` — DR procedures (numbering jumps from 04 to 06 — `05-LGPD.md` referenced but missing)
- `DESIGN-PROMPT.md` — **Obsolete** (prompt to generate the prototype that's now approved)
- `DESIGN-SYSTEM.md` — Tokens, components (**missing the `neon` color used in approved prototype**)
- `FEATURES.md` — F01–F15 business rules ✅ HIGH VALUE
- `SCREENS.md` — Spoke/Circuit screen map ✅ HIGH VALUE (**talks about 12 screens; prototype has 19**)
- `INFRA-ACCESS.md` — DO + Vercel access (**says "not yet provisioned"; user confirmed both ready**)

### docs/decisions/ (11)
- ADRs 0000–0010 — All preserved as-is

### docs/sessions/ (4)
- 0000-template + 0001-INDEX + 3 session logs — All preserved

### .github/, infra/, scripts/, apps/ — Folders (mostly placeholders with .gitkeep)
- `apps/admin/` — Empty placeholder. Admin is M2 and will be front-only mock — doesn't need a separate app folder; can live as a route inside `apps/landing/` or be deferred entirely.

---

## Final structure (after cleanup)

### Root (5 files)
```
README.md         # Rewritten — reflects M1-full / M2-front-only, prototype approved
CLAUDE.md         # Rewritten leaner — points to docs/ for detail
CONTRIBUTING.md   # Cleaned — git workflow without osascript section
SECURITY.md       # Kept as-is
TODO.md           # Rewritten from scratch — aligned with new roadmap
```

### docs/ (10 files, contiguous numbering 01–10)
```
01-PROJECT.md         # Updated: M1 full-stack, M2 front-only, DO+Vercel provisioned
02-ARCHITECTURE.md    # Updated: prototype as canonical UI source
03-CONVENTIONS.md     # Minor updates (kept structure)
04-FEATURES.md        # Renumbered from FEATURES.md, content preserved
05-SCREENS.md         # Renumbered + REWRITTEN: 19 prototype screens with Spoke/Circuit mapping retained
06-DESIGN-SYSTEM.md   # Renumbered + UPDATED: neon token added, components matched to prototype
07-INFRA.md           # Replaces INFRA-ACCESS.md: DO and Vercel marked as provisioned
08-ROADMAP.md         # NEW: unified roadmap, M1 full-stack + M2 front-only
09-DISASTER-RECOVERY.md # Renumbered from 06, content preserved
10-CHANGELOG.md       # NEW: section "Documentation reorganization 2026-05-07"
```

### docs/decisions/ (11 files — unchanged)
```
0000-template.md       # Kept
0001 to 0010           # Kept as-is
# ADR-0011 explicitly NOT created — see "M2 deferred" decision in spec
```

### docs/sessions/ (5 files)
```
0000-template.md, 0001-INDEX.md, 3 existing logs   # Kept
2026-05-07-04-docs-cleanup.md  # NEW: this work's session log
```

### apps/
```
apps/landing/    # Kept (placeholder ready)
apps/backend/    # Kept (placeholder ready)
apps/mobile/     # Kept (placeholder ready)
                 # apps/admin/ DELETED — M2 admin lives inside landing or deferred
```

### Other folders
```
.github/         # Kept
infra/           # Kept
scripts/         # Kept
prototipo/       # Kept untouched — canonical source
```

### Files moved
```
logo.png  →  apps/landing/public/logo.png
```

### Files deleted
```
agents.md
CODE_OF_CONDUCT.md
docs/DESIGN-PROMPT.md
docs/04-ROADMAP-M1.md
docs/04-ROADMAP-M2.md
apps/admin/
```

---

## File-by-file changes

### `CLAUDE.md` — Rewrite (lean)

Goals: shorter, points to canonical docs, removes ambiguity, **focused on M1**.

Sections:
- What this project is (1 paragraph).
- Onboarding ritual: read README → CLAUDE.md → TODO.md → docs/08-ROADMAP.md → docs/sessions last 3.
- **Current focus: M1** — explicit one-liner reminding agents not to plan/build M2 work.
- Karpathy's four principles (kept).
- Project-specific critical rules:
  - Stack table (kept, with note "see ADRs for rationale").
  - Context7 mandatory rule (kept).
  - Verify your work (kept).
  - Filesystem protocol (kept).
  - Git protocol — short, no osascript, no Mac-specific noise.
  - Secrets (kept).
- Session end protocol (kept).
- References pointing to `docs/`.

Drops: `agents.md` cross-reference (file deleted), CODE_OF_CONDUCT reference, content already in docs/02-ARCHITECTURE, any handoff/transfer mechanics.

Length target: ~180 lines.

### `agents.md` — DELETE

Rationale: 100% redundant with CLAUDE.md. Anything truly agent-specific moves into CLAUDE.md or stays in `.claude/`.

### `CONTRIBUTING.md` — Update

Drops:
- "Mac Workflow (osascript)" entire section — irrelevant; we run inside Claude Code.
- "External human contributors" framing — only Eduardo and AI agents.
- Any references to handoff / repo transfer mechanics — Eduardo handles those with the client outside the docs.

Keeps: Conventional Commits format, branching model, push rules.

### `SECURITY.md` — Keep as-is

Solid as is. References `docs/06-DISASTER-RECOVERY.md` which becomes `docs/09-DISASTER-RECOVERY.md` — fix the link.

### `CODE_OF_CONDUCT.md` — DELETE

Rationale: solo project + single client + no public contributor surface. Adds noise.

### `TODO.md` — Rewrite from scratch (M1-only)

New shape (≤ 100 lines):
- Header: M1 deadline 2026-05-26, status, last updated.
- **Phase 1 — Foundations**
  - Flutter project init (apps/mobile) — auth-only scope for M1
  - Backend project init (apps/backend)
  - Landing project init (apps/landing)
  - Local Docker stack (postgres, redis, graphhopper)
- **Phase 2 — M1 features**
  - Backend auth: register, login, refresh, me + healthchecks
  - Flutter auth: Login + Register screens matching prototype 1:1
  - Landing pages: hero, product details, FAQ, contact, APK CTA placeholder
  - GraphHopper SP graph + benchmark (p95 < 200ms)
- **Phase 3 — M1 deploy**
  - Server hardening on DO 1GB
  - docker compose deploy
  - Nginx + HTTPS for `api.roteirizadorpro.com.br`
  - Vercel domain config for `roteirizadorpro.com.br`
  - Postgres backup cron + droplet snapshot
- **Phase 4 — M1 acceptance**
  - Smoke test all 4 acceptance criteria
  - `docs/INSTALL.md` written and tested
  - Demo video recorded (Loom)
- **Discovered while working** section (empty initially)
- **Done** section preserved (existing entries kept)

Removes: blocker section, "Phase 4 — M2 front-only" planning, sprint-by-sprint plans (live in `docs/08-ROADMAP.md`), references to handoff/transfer mechanics.

### `docs/01-PROJECT.md` — Update

Changes:
- Replace "14 days per milestone" with **"30 days per milestone (M1 accepted 2026-04-26, deadline 2026-05-26)"**.
- M1 scope: "full-stack functional on a 1GB droplet (workaround agreed with client). SP-only GraphHopper. Resize to 8GB + Sudeste reimport is post-M1 work."
- M1 mobile clarification: "Only Login + Register screens implemented in Flutter for M1; the remaining 17 prototype screens are M2 work."
- M2 stays as a single short paragraph: "Post-M1. Scope to be reconfirmed with client after M1 acceptance. Original Workana scope: APK + Pix Split + paywall + admin + sentido casa optimization."
- Add note: "Visual and flow source of truth is `prototipo/`."
- Drop any references to ownership transfer / handoff mechanics — those are handled by Eduardo with the client outside the documentation.

### `docs/02-ARCHITECTURE.md` — Update

Changes:
- Prepend a "UI source of truth" callout pointing to `prototipo/` and `docs/05-SCREENS.md`.
- Mobile section: clarify M1 implements only Login + Register; remaining 17 screens are M2 work.
- Endpoints section: split into "M1 endpoints (implementing)" and "M2 endpoints (post-M1, scope to reconfirm)" — keep both lists for reference but mark clearly.
- Pix Split / Efí section: keep existing description as M2 reference material; move to a clearly-labeled "M2 — post-M1 reference" subsection.

### `docs/03-CONVENTIONS.md` — Light update

Changes:
- Add row to directory layout: `prototipo/` (canonical UI reference, never imported, never built).
- Keep everything else.

### `docs/04-FEATURES.md` (renamed from `FEATURES.md`) — Light update

Changes:
- Status column update: F01 → "M1"; F14 → "M1"; F15 → "M1"; F02–F13 → "M2 (post-M1, scope to reconfirm)".
- No mock-behavior subsections — that's M2 implementation detail and not planned in this pass.
- Content of each feature spec is preserved as the canonical reference for what was contracted.

### `docs/05-SCREENS.md` (renamed from `SCREENS.md`) — REWRITE

Two parts:
1. **Prototype screen map (19 screens)** — primary section, pulled directly from `prototipo/Roteirizador Pro.html`:
   - **M1 scope:** 01 Login, 02 Register
   - **M2 (post-M1):** 03 Home empty, 04 Stop list, 05 Map view, 06 Add via map, 07 Add (search), 08 Edit stop, 09 Voice, 10 OCR, 11 Optimizing, 12 Optimized route, 13 Reorder, 14 Stop detail, 15 Turn-by-turn navigation, 16 Route complete, 17 Paywall (Pix), 18 Settings, 19 Share/referral
   For each: purpose, gestures/interactions, when it appears, screen ID for code reference. M1 screens get the most detail; M2 screens documented at "what they are" level (since implementation isn't planned yet).
2. **Spoke/Circuit feature mapping** — secondary section, preserved as reference: which Spoke screens we replicate functionally and which we deliberately exclude (the existing table is reused).

### `docs/06-DESIGN-SYSTEM.md` (renamed from `DESIGN-SYSTEM.md`) — UPDATE

Changes:
- Add `neon` color triplet (`#C6FF3D`, `#9BCC1F`, `#F1FFCC`, ink `#3D5400`) — currently missing from docs but present in prototype.
- Note: "all tokens mirror `prototipo/tokens.js` — that file is canonical".
- Components section: align radii (`rCard:16, rBtn:24, rInput:12, rSheet:20`) with prototype.
- Remove any conflicting values found in the audit.

### `docs/DESIGN-PROMPT.md` — DELETE

Rationale: that prompt produced the prototype. Prototype is approved. Prompt is now historical noise.

### `docs/04-ROADMAP-M1.md` and `docs/04-ROADMAP-M2.md` — DELETE

Replaced by unified `docs/08-ROADMAP.md`.

### `docs/07-INFRA.md` (renamed from `INFRA-ACCESS.md`) — UPDATE

Changes:
- DigitalOcean: mark as **provisioned**. Confirm the 1GB plan workaround is current state. Fields to fill: droplet IP, hostname, region (user fills manually).
- Vercel: mark as **provisioned**. Fields to fill: project name, staging URL.
- Remove "client must provision" section — done.
- Remove every reference to "ownership transfer", "handoff", "transferring Vercel project", "transferring GitHub repo". Eduardo handles those interactions with the client directly outside of documentation.
- Keep first-login sequence, Docker install, directory structure, DNS records.
- Keep secrets inventory (renamed to "M1 secrets" — items only relevant to M2 like Efí .p12 are removed from this pass).

### `docs/08-ROADMAP.md` — NEW (M1-only)

Single roadmap focused entirely on M1. Sections:
- Status header: deadline 2026-05-26, days remaining as of last update.
- M1 acceptance criteria (verbatim from Workana — 4 criteria).
- Plan in 4 phases, each with success criterion and concrete tasks (no day-by-day plan — phases sequential or parallel as appropriate):
  - Phase 1 — Foundations: Flutter project init, backend project init, landing init, local Docker stack.
  - Phase 2 — M1 features: backend auth (register/login/refresh/me + healthchecks), Flutter auth screens (Login + Register), landing page sections, GraphHopper SP graph + benchmark.
  - Phase 3 — M1 deploy: server hardening on DO 1GB, docker compose deploy, Nginx + HTTPS for api subdomain, Vercel domain config, Postgres backup cron, droplet snapshot.
  - Phase 4 — M1 acceptance: end-to-end smoke test of all 4 acceptance criteria, install manual (`docs/INSTALL.md`), demo video.
- Deliverables checklist (M1 only).
- Risks register (M1-relevant only — DNS propagation, GraphHopper p95, etc.).
- Out of scope for M1 (anything M2-related goes here as a single bullet pointing to FEATURES.md for the contracted M2 catalogue).
- Final section: "After M1 acceptance — next steps" — single short paragraph: "Reconfirm M2 scope with client, agree on approach (full implementation vs phased)."

Length target: ~150 lines (M2 detail removed cuts the size in half).

### `docs/09-DISASTER-RECOVERY.md` (renamed from `06-DISASTER-RECOVERY.md`) — Light update

Changes:
- Fix internal links pointing to old numbering.
- Mark "Tested?" column with M1 reality (mostly still ❌).

### `docs/10-CHANGELOG.md` — NEW

A simple changelog scoped to docs structure changes (so future agents see the reorganization happened).

First entry:
```
## 2026-05-07
- Documentation reorganization: removed redundant files (agents.md,
  CODE_OF_CONDUCT.md, DESIGN-PROMPT.md), unified roadmap into
  08-ROADMAP.md (M1-only), renumbered docs to be contiguous, aligned
  with approved prototype as canonical UI source.
- Roadmap focused entirely on M1 delivery (deadline 2026-05-26). M2
  scope deferred for client conversation post-M1.
```

### `docs/decisions/0011-m2-front-only.md` — NOT CREATED

Originally proposed but **dropped**. Decision: M2 scope is deferred — to be reconfirmed with the client after M1 acceptance. No ADR until that conversation happens. Avoids documenting an internal decision that wasn't actually agreed with the client.

### `docs/sessions/2026-05-07-04-docs-cleanup.md` — NEW

Session log following template, summarizing this reorganization.

### `docs/sessions/0001-INDEX.md` — Append entry

```
- [2026-05-07-04 — docs-cleanup](./2026-05-07-04-docs-cleanup.md) — Reorganized docs, removed redundant files, unified roadmap, aligned with approved prototype.
```

### `apps/admin/` — DELETE folder

Replaced by: nothing for now. M2 admin will be a route inside `apps/landing/` if implemented.

### `logo.png` — MOVE to `apps/landing/public/logo.png`

(Will be picked up by Next.js automatically at landing time.)

---

## Execution order (for the implementation plan)

Order matters to avoid broken references mid-work and preserve git history:

1. **Snapshot current state** — `git status` confirms clean tree before starting.
2. **Rename existing files first** via `git mv` (preserves history; subsequent edits operate at new paths):
   - `docs/FEATURES.md` → `docs/04-FEATURES.md`
   - `docs/SCREENS.md` → `docs/05-SCREENS.md`
   - `docs/DESIGN-SYSTEM.md` → `docs/06-DESIGN-SYSTEM.md`
   - `docs/INFRA-ACCESS.md` → `docs/07-INFRA.md`
   - `docs/06-DISASTER-RECOVERY.md` → `docs/09-DISASTER-RECOVERY.md`
   - Commit: `docs(structure): renumber and rename for contiguous order`.
3. **Move logo**:
   - Create `apps/landing/public/` if missing.
   - `git mv logo.png apps/landing/public/logo.png`.
   - Commit: `chore: move logo to landing public assets`.
4. **Create new files** (additions, no conflicts):
   - `docs/08-ROADMAP.md` (M1-only)
   - `docs/10-CHANGELOG.md`
   - Commit: `docs(roadmap): add M1 roadmap and changelog`.
5. **Rewrite/update files at new paths**:
   - `docs/05-SCREENS.md` (rewrite — 19 screens from prototype + Spoke mapping retained)
   - `docs/06-DESIGN-SYSTEM.md` (update — neon token, prototype radii)
   - `docs/04-FEATURES.md` (update — mock behavior subsections for M2 front-only features)
   - `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`, `docs/07-INFRA.md`, `docs/09-DISASTER-RECOVERY.md`
   - Root: `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, `TODO.md`, `SECURITY.md` (link fix only)
   - Commit: `docs(rewrite): align with approved prototype and M2 front-only scope`.
6. **Delete obsolete files**:
   - `agents.md`
   - `CODE_OF_CONDUCT.md`
   - `docs/DESIGN-PROMPT.md`
   - `docs/04-ROADMAP-M1.md`
   - `docs/04-ROADMAP-M2.md`
   - `apps/admin/` (entire folder)
   - Commit: `docs(cleanup): remove obsolete files`.
7. **Write session log** `docs/sessions/2026-05-07-04-docs-cleanup.md` (must come before index update so the link is valid when committed).
8. **Append session log entry** to `docs/sessions/0001-INDEX.md`.
   - Commit: `docs(sessions): add 2026-05-07-04 docs cleanup`.
9. **Verification pass** — run the success criteria checks below; fix anything found.

---

## Verification (success criteria)

After this work is done:

1. **No file in `docs/` references a file that doesn't exist.** Verified by grepping every `[link](path)` and confirming the target exists.
2. **No two files describe the same screen, feature, or rule with conflicting values.** Verified by reading: only `06-DESIGN-SYSTEM.md` defines colors; only `05-SCREENS.md` defines screen list; only `08-ROADMAP.md` defines M1 phases.
3. **`prototipo/tokens.js` colors match `docs/06-DESIGN-SYSTEM.md` color table 1:1** (including the `neon` token).
4. **`prototipo/Roteirizador Pro.html` 19 screen IDs match `docs/05-SCREENS.md` listing 1:1.** M1 screens (01 Login, 02 Register) explicitly tagged.
5. **`TODO.md` and `docs/08-ROADMAP.md` describe M1-only work.** No Phase 4 of M2, no front-only mock planning, no transfer/handoff mechanics.
6. **`README.md` "Repository Structure" section matches actual directory layout.**
7. **No file mentions "ownership transfer", "handoff to client", or "transfer Vercel project"** (Eduardo's call — those interactions are outside docs).
8. **`git status` after the work shows zero leftover renamed/deleted files; all changes committed.**

---

## Open questions (must be resolved during/after this spec, not before)

- Droplet IP for `docs/07-INFRA.md`: user fills in manually.
- Vercel project name and staging URL: user fills in manually.
- M2 scope: deferred until M1 acceptance. Reconfirmation with client happens then.

---

## Out of scope for this spec

- Writing Flutter code.
- Provisioning Vercel/DO further than what's already done.
- Adding new ADRs beyond 0011.
- Changing CONTRIBUTING.md branching model.
- Translating docs to PT-BR.
