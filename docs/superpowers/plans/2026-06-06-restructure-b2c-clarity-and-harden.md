# Restructure: B2C clarity + harness hardening — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan microsprint-by-microsprint with a review checkpoint at each MS boundary. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure how the remaining Roteirizador Pro work is scoped and guarded — without changing product behavior — so the recurring stale-baseline and scope-ambiguity failures stop. Produces: a researched B2C/B2B boundary doc + ADR, roadmap annotations, a generalized Spoke-clone workflow, a live-inspect-per-feature contract in versioned files, a two-track execution model, a hard `integration_test/` per-area gate, thin live-inspect-first stubs for Áreas 6–9, and surgical cleanup. Zero `lib/`/`src/` edits.

**Architecture:** No new module. Six microsprints, each one or more logical commits, all diffs confined to `docs/`, `.claude/`, `.gitignore`, and the project memory dir. The B2C/B2B boundary doc (MS1) is the keystone the rest references.

**Tech Stack:** Markdown docs; one ADR; Workflow DevKit JS (`.claude/workflows/`); agent definitions (`.claude/agents/`). No runtime dependency, no `package.json` change. Stack lock unchanged — refer to ADR-0011 (Node 20) / project stack table in CLAUDE.md.

**Spec:** `docs/superpowers/specs/2026-06-06-restructure-b2c-clarity-and-harden.md`

**Branch:** `chore/restructure-b2c-harden` (off the current branch tip `e48cdaf`, to be created in Phase 0).

---

## Working directory

All commands assume `cwd` is the repo root:
`/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/app-roteirizadorpro`

From here on, paths are repo-root-relative.

## Plan execution rules

1. **One MS = one or more logical commits.** Each commit uses Conventional Commits + a valid scope from `commitlint.config.cjs`. Lefthook runs hooks; since no `lib/`/`src/` changes, mobile analyze/typecheck hooks are no-ops but must still pass.
2. **No `lib/` or `src/` edits — ever.** This is a docs + harness sprint. Before every commit, `git diff --cached --stat` must show only `docs/`, `.claude/`, `.gitignore`, or memory paths. A staged `apps/*/lib/**` or `apps/*/src/**` file is a STOP condition — unstage and investigate.
3. **No `--no-verify`.** If a hook fails, fix the underlying issue.
4. **Surgical edits only.** Annotate, don't rewrite. Match existing doc tone (the inventory + roadmap are dense and Portuguese-leaning; new docs mirror that register).
5. **Cite every B2C/B2B classification.** No row in the boundary doc without an official-source URL.
6. **Push after each completed MS** (`git push`). Open the PR only after MS6's release tasks complete.
7. **Checkpoint discipline** (`lesson_checkpoint_discipline_between_microsprints`): at each MS boundary, run `git push` + update `TODO.md` status sub-bullet before starting the next MS.

## File structure created/modified by this plan

### Docs (`docs/`)

```
docs/
├── decisions/
│   └── 0044-spoke-b2c-vs-b2b-scope-boundary.md          [CREATE]
├── inventory/
│   ├── 2026-06-06-spoke-b2c-vs-b2b-boundary.md          [CREATE]
│   └── 2026-05-26-spoke-vs-rotpro.md                    [MODIFY — §12 gap-table annotations]
├── 08-ROADMAP-v2.md                                     [MODIFY — 2 row annotations + two-track section + boundary link]
├── M2-SLICE-CHECKLIST.md                                [MODIFY — live-inspect rule + integration_test gate]
├── superpowers/specs/
│   ├── 2026-06-06-area6-stub.md                         [CREATE — thin INFERRED stub]
│   ├── 2026-06-06-area7-stub.md                         [CREATE]
│   ├── 2026-06-06-area8-stub.md                         [CREATE]
│   └── 2026-06-06-area9-stub.md                         [CREATE]
├── 10-CHANGELOG.md                                      [MODIFY — restructure entry]
└── audits/
    └── 2026-06-06-restructure-closure.md                [CREATE — closure report]
```

(The exact set of Áreas 6–9 stubs is finalized in MS5 against the live roadmap — the roadmap is the authority on which areas remain unbuilt; the plan reads it rather than hardcoding the list.)

### Harness (`.claude/`)

```
.claude/
├── workflows/
│   └── spoke-microsprint.js                             [CREATE — renamed from area5-microsprint.js, generalized]
│   └── area5-microsprint.js                             [DELETE after rename, OR keep as thin alias — decided in MS3]
└── agents/
    └── spoke-parity-checker.md                          [MODIFY — live-inspect contract clause]
```

### Root + memory

```
.gitignore                                               [MODIFY — guard inspection captures, if not already covered]
~/.claude/projects/.../memory/MEMORY.md                  [MODIFY — pointer fix if needed]
docs/decisions/0042-time-picker-numpad-spoke-fidelity.md [MODIFY — fix dangling memory ref, line 53]
```

---

## Phase 0 — Pre-flight (no commits)

### Task 0: Verify environment

**Files:** none (read-only checks).

- [ ] **Step 0.1: Confirm clean tree + create the branch**

Run:
```bash
git status
git rev-parse --abbrev-ref HEAD
git log --oneline -3
git checkout -b chore/restructure-b2c-harden
```

Expected: working tree clean before branching; HEAD at `e48cdaf` (the revalidation spec commit) or later. New branch `chore/restructure-b2c-harden` created.

If the tree is dirty: STOP. Stash or commit unrelated work first — this sprint must start clean to keep its diff auditable.

- [ ] **Step 0.2: Re-read the spec + the B2C/B2B research**

Open `docs/superpowers/specs/2026-06-06-restructure-b2c-clarity-and-harden.md`. Re-read §Context (the B2C/B2B classification) and §Decisions Locked. This is the contract every MS upholds. The classification is the load-bearing fact: **time-window + priority are B2C; B2B is Spoke Dispatch (assign/track/team/notify/analytics); nothing needs cutting.**

- [ ] **Step 0.3: Confirm the regression baseline (so MS6 can prove no regression)**

Run:
```bash
cd apps/mobile && flutter analyze 2>&1 | tail -3 && cd ../..
```

Expected: ~23 issues, all pre-existing in `routes`. Record the exact count — MS6 must not exceed it. (Skip `flutter test` here to save time; MS6 runs the full sweep.)

No commit — Phase 0 is read-only except for the branch creation.

---

## Phase MS1 — B2C/B2B boundary doc + ADR

This MS produces the keystone: the researched classification as both an inventory doc and a versioned ADR. Everything downstream references it.

### Task 1: Write the B2C/B2B boundary inventory doc

**Files:**
- Create: `docs/inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md`

- [ ] **Step 1.1: Author the boundary doc**

Create the file with these sections (content drawn from the spec's §Context "B2C/B2B boundary" — reproduce the classification, do not summarize it away):

1. **Header** — date 2026-06-06, research-based, status canonical.
2. **The rebrand fact** — Circuit → Spoke (late 2025); `help.getcircuit.com` → `help.spoke.com`; "Circuit for Teams" → "Spoke Dispatch"; our clone target `com.underwood.route_optimiser` = consumer **Spoke Route Planner**.
3. **The decision rule** (the one-liner future agents apply):
   > **Does this feature serve a dispatcher managing OTHER drivers, or a company admin managing a fleet/team/customer-notifications? → B2B (Spoke Dispatch) → DO NOT clone. Does it serve one solo driver planning and running their own route? → B2C (Spoke Route Planner) → in scope.**
4. **Classification table** — one row per feature, columns: `Feature | Tier (B2C Route Planner / B2B Dispatch) | Source`. Rows MUST include, each cited:
   - route optimization · B2C · spoke.com/route-planner
   - per-stop **time windows** · **B2C** · help/route-planner ("set delivery time windows … for specific stops")
   - per-stop **priority** · **B2C** · help/route-planner ("set … priority levels for specific stops")
   - proof of delivery (photo + notes) · B2C · spoke.com/route-planner
   - package finder / package count · B2C · spoke.com/route-planner
   - delivery vs pickup, rest breaks, custom stop duration, voice entry, in-app navigation · B2C · route-planner pages
   - assign stops to other drivers · **B2B** · getcircuit.com/teams
   - live GPS fleet tracking · **B2B** · getcircuit.com/teams
   - team/member management + roles/permissions · **B2B** · getcircuit.com/teams
   - automatic customer notifications (ETA SMS) · **B2B** · getcircuit.com/teams
   - recipient-facing tracking pages · **B2B** · getcircuit.com/teams
   - driver-performance analytics dashboard · **B2B** · routific review
   - company billing per seat · **B2B** · getcircuit.com/teams
   - integrations (Shopify/Zapier) · **B2B** · getcircuit.com/teams
5. **Verification-against-our-surface** record:
   - **Already cut:** Maximum-stops-per-plan tier limit (inventory §12.B.10) — removed by ADR-0030 single-tier model.
   - **Verified-clean (do NOT re-flag):** per-stop time-window (roadmap:132, inventory §12.B.7) and per-stop priority (roadmap:253/259, §12.B.7b) are **B2C** — keep. Cutting them would violate locked directives #7.2 + #13.
   - **Built code scan (2026-06-06):** zero Dispatch concepts in `apps/mobile/lib/{auth,routes,route_config}` + `apps/backend/src/{auth,health,routes,config,plugins}`. Only false positives (`_rememberMe`, Riverpod `dispatch`, `SqlDriverAdapter`).
   - **Painel admin (Slice 7):** original RotPro internal tooling, NOT the B2B Dispatch dashboard (which is customer-facing fleet mgmt). Stays in scope as an original feature.
6. **Sources** — the 4 official URLs from the spec's References.

- [ ] **Step 1.2: Verify the doc**

```bash
test -f docs/inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md && grep -c "B2C\|B2B" docs/inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md
```

Expected: file exists; many B2C/B2B mentions. Every B2B row in the table must have a source URL — eyeball the table.

- [ ] **Step 1.3: Commit**

```bash
git add docs/inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md
git commit -m "$(cat <<'EOF'
docs(inventory): canonical Spoke B2C vs B2B Dispatch scope boundary

Researched classification (official Spoke/Circuit docs, 2026-06-06):
Route Planner (solo) vs Dispatch (fleet). Records that per-stop
time-window + priority are B2C (keep), the only B2B feature
(max-stops-per-plan) was already cut by ADR-0030, and our built
surface is clean of Dispatch concepts. The decision rule future
agents apply when an area touches an ambiguous feature.
EOF
)"
```

### Task 2: File ADR-0044 for the scope boundary

**Files:**
- Create: `docs/decisions/0044-spoke-b2c-vs-b2b-scope-boundary.md`

- [ ] **Step 2.1: Confirm the ADR number is still free**

```bash
ls docs/decisions/ | grep -oE '^[0-9]{4}' | sort -n | tail -1
```

Expected: `0043`. If it shows `0044` or higher (another session filed one), use the next free number and adjust all references in this plan + the spec.

- [ ] **Step 2.2: Write the ADR**

Create `docs/decisions/0044-spoke-b2c-vs-b2b-scope-boundary.md` following the project ADR format (H1 `# ADR-0044: Spoke Route Planner (B2C) vs Spoke Dispatch (B2B) scope boundary`, then Status / Context / Decision / Consequences). Status: Accepted, 2026-06-06. The Decision section states: we clone ONLY the B2C Spoke Route Planner; the boundary doc `docs/inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md` is canonical; the decision rule is binding for every future area; the admin panel is an original RotPro feature, not the B2B Dispatch dashboard. Cross-reference ADR-0030 (single-tier, which already cut the one B2B feature), ADR-0035 (Spoke white-label).

- [ ] **Step 2.3: Verify title well-formed (avoids the ADR-0018/0040 malformed-title bug)**

```bash
head -1 docs/decisions/0044-spoke-b2c-vs-b2b-scope-boundary.md
```

Expected exactly: `# ADR-0044: Spoke Route Planner (B2C) vs Spoke Dispatch (B2B) scope boundary` — single `#`, hyphen in `ADR-0044`, colon after.

- [ ] **Step 2.4: Commit**

```bash
git add docs/decisions/0044-spoke-b2c-vs-b2b-scope-boundary.md
git commit -m "$(cat <<'EOF'
docs(decisions): ADR-0044 Spoke B2C vs B2B Dispatch scope boundary

Versioned decision: clone only the B2C Route Planner; Dispatch
(assign/track/team/notify/analytics) is out of scope. Boundary doc
is canonical; decision rule binds every future area. Admin panel is
original RotPro tooling, not the Dispatch dashboard.
EOF
)"
```

**MS1 gate:** boundary doc + ADR-0044 committed; every B2B classification row cited; ADR title well-formed. `git push`. Update `TODO.md` (add a "Restructure sprint" sub-section, MS1 ✅).

---

## Phase MS2 — Roadmap annotations + two-track model

Annotate the two B2C rows so no future agent re-flags them; add the two-track execution section; link the boundary doc. Surgical — 2 rows + 1 section + links.

### Task 3: Annotate the two B2C rows + the schema priority column

**Files:**
- Modify: `docs/08-ROADMAP-v2.md` (around lines 132, 253, 259)
- Modify: `docs/inventory/2026-05-26-spoke-vs-rotpro.md` (§12 gap table rows B.7 / B.7b)

- [ ] **Step 3.1: Annotate roadmap:132 (per-stop time-window)**

Find the line (the `Row "Horário de chegada"` bullet) and append, in-line, a B2C marker so the existing text is preserved and a clause is added:
`… Detalhe em inventory §10.6 + §12.B.7. **(B2C — Spoke Route Planner; NÃO é B2B. Ver [boundary doc](./inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md).)**`

- [ ] **Step 3.2: Annotate roadmap:253/259 (per-stop priority)**

On the `POST /routes/optimize` constraints line (253) and/or the `Stops schema` line (259), append a parenthetical to the `priority` mention:
`… priority (per stop) **[B2C — Spoke Route Planner; ver boundary doc]** …`

Keep it minimal — one clause per line, no restructure of the bullet.

- [ ] **Step 3.3: Annotate the inventory §12 gap-table rows**

In `docs/inventory/2026-05-26-spoke-vs-rotpro.md`, the §12 table rows B.7 and B.7b currently say "útil pra B2B". Append a correction clause to each (do NOT delete the original wording — annotate it):
`… útil pra B2B **— CORREÇÃO 2026-06-06: feature é B2C (Spoke Route Planner suporta time-window + priority pra motorista solo per doc oficial). Ver boundary doc. Manter em escopo.**`

- [ ] **Step 3.4: Verify + commit**

```bash
grep -n "boundary doc\|B2C — Spoke Route Planner\|CORREÇÃO 2026-06-06" docs/08-ROADMAP-v2.md docs/inventory/2026-05-26-spoke-vs-rotpro.md
git add docs/08-ROADMAP-v2.md docs/inventory/2026-05-26-spoke-vs-rotpro.md
git commit -m "$(cat <<'EOF'
docs(scope): annotate per-stop time-window + priority as B2C

Official Spoke docs confirm both are Route Planner (solo) features,
not Dispatch (B2B). Annotate the roadmap rows + the inventory §12
gap-table "útil pra B2B" tags so no future agent re-flags them for
removal. Links to the 2026-06-06 boundary doc.
EOF
)"
```

### Task 4: Add the two-track execution section to the roadmap

**Files:**
- Modify: `docs/08-ROADMAP-v2.md` (new section near the top, after the strategy preamble)

- [ ] **Step 4.1: Insert the "How remaining work is executed" section**

Add a concise section distinguishing the two tracks (content from spec Goal #5):

```markdown
## Como o trabalho restante é executado (dois trilhos)

> Per [ADR-0044](./decisions/0044-spoke-b2c-vs-b2b-scope-boundary.md) + [boundary doc](./inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md).

**Trilho 1 — Clone do Spoke (Áreas 6–9 do Slice 2).** Spoke é o spec. Fluxo:
stub fino live-inspect-first → confirmar M54 + Spoke logado → `spoke-microsprint.js`
(Phase 0 byte-check baseline → Phase 1 baseline LIVE com halt em surpresa
arquitetural → research → implementa → review duplo) → gate `integration_test/`
se mexeu navegação. NÃO pré-escrever spec longa (baka baseline obsoleta — foi a
falha de MS4/MS5). Inspeção LIVE no momento da implementação é obrigatória.

**Trilho 2 — Features originais RotPro (Slices 4/5/6/7).** Sem equivalente Spoke,
então SEM `spoke-parity-checker`, SEM live-inspect. Fluxo pesado normal:
`superpowers:brainstorming` → spec completa → plano completo → executa. Slice 4
(Stripe Pix), 5 (sentido casa), 6 (LGPD), 7 (painel admin — ferramenta interna,
NÃO o dashboard B2B Dispatch).
```

Place it after the strategy preamble / restrictions block, before "Slice 1".

- [ ] **Step 4.2: Verify + commit**

```bash
grep -n "dois trilhos\|Trilho 1\|Trilho 2" docs/08-ROADMAP-v2.md
git add docs/08-ROADMAP-v2.md
git commit -m "$(cat <<'EOF'
docs(roadmap): document two-track execution model

Trilho 1 (Spoke-clone Áreas 6-9): spoke-microsprint.js, live-inspect
is the spec, thin stub only. Trilho 2 (original Slices 4-7): full
brainstorm→spec→plan, no Spoke equivalent. Codifies the live-inspect
discipline that MS4/MS5 violated by trusting a pre-written baseline.
EOF
)"
```

**MS2 gate:** 2 rows annotated, inventory §12 corrected, two-track section added, all linking the boundary doc. `git push`. Update `TODO.md` (MS2 ✅).

---

## Phase MS3 — Generalize the workflow

`area5-microsprint.js` → `spoke-microsprint.js`. The workflow is already ~95% generic; this MS renames it, parameterizes the one hardcoded screenshot path, updates `meta.name`, resolves the skill registration, and preserves EVERY halt gate verbatim.

### Task 5: Find all references to the old workflow name

**Files:** none (read-only).

- [ ] **Step 5.1: Grep for callers + registrations**

```bash
grep -rn "area5-microsprint" .claude/ docs/ ~/.claude/projects/-Users-eduardorodrigues-Documents-Projetos-Clientes-ueslei-workana-app-roteirizadorpro/memory/ 2>/dev/null
```

Record every hit. These are the references to update in Task 6/7 so nothing dangles after the rename.

### Task 6: Create the generalized workflow

**Files:**
- Create: `.claude/workflows/spoke-microsprint.js`

- [ ] **Step 6.1: Copy + generalize**

Copy `.claude/workflows/area5-microsprint.js` to `.claude/workflows/spoke-microsprint.js`, then apply EXACTLY these generalizations (and NO behavioral change to any gate):

1. `meta.name`: `'area5-microsprint'` → `'spoke-microsprint'`.
2. `meta.description`: → `'Reusable Spoke-clone microsprint dispatch with executable halt gates and spec-baseline preflight'`.
3. The header comment block: update `Area 5 microsprint dispatch template (MS4-MS8 reusable)` → `Spoke-clone microsprint dispatch template (any area, reusable)`; update the invocation example to include `areaSlug`.
4. Add `areaSlug` to the args contract — a new OPTIONAL arg (default `'a5'` for back-compat) used to build the screenshot directory. In the Phase 1 prompt, replace the hardcoded `/tmp/spoke-a5-inspection/ms${cfg.msNumber}-*.png` with `/tmp/spoke-${cfg.areaSlug || 'a5'}-inspection/ms${cfg.msNumber}-*.png`. Add a line after the `cfg` parse: `cfg.areaSlug = cfg.areaSlug || 'a5'`.
5. Leave ALL halt logic byte-for-byte: the `PREFLIGHT_SCHEMA` byte-check, the `[INFERRED]` heuristic, the `architectural-surprise` defensive halt, the `BLOCKED_SPEC_OUTDATED` / `BLOCKED_OTHER` returns, the `techDebtIntroduced` non-empty halt, the dual review. Do not "improve" them.

- [ ] **Step 6.2: Validate it parses**

Invoke the Workflow tool with the new script path and a deliberately-incomplete args to trigger the required-args validation (which proves the script loaded + the guards fire WITHOUT running any agent):

```
Workflow({ scriptPath: ".claude/workflows/spoke-microsprint.js", args: {} })
```

Expected: it throws the `missing required arg` error (NOT a syntax error). A syntax error means the generalization broke the file — fix before committing. (Do NOT run it with full args — that would dispatch real agents; this sprint only validates the script loads.)

- [ ] **Step 6.3: Decide alias vs delete the old file**

Per the Task 5 grep:
- If the only references to `area5-microsprint` are the skill registration + this plan/spec/session docs → **delete** `area5-microsprint.js` and update the skill registration to `spoke-microsprint` (Task 7).
- If there is any other live caller that's hard to update atomically → keep `area5-microsprint.js` as a 2-line thin alias that re-exports / re-invokes `spoke-microsprint.js`, and note it as deprecated.

Default expectation: delete + re-register (cleaner; the workflow has no programmatic callers, only skill invocation).

- [ ] **Step 6.4: Commit**

```bash
git add .claude/workflows/spoke-microsprint.js
git rm .claude/workflows/area5-microsprint.js   # only if Step 6.3 chose delete
git commit -m "$(cat <<'EOF'
chore(workflows): generalize area5-microsprint -> spoke-microsprint

Rename + parameterize the screenshot dir via areaSlug (defaults to
'a5' for back-compat). Every halt gate preserved verbatim: preflight
byte-check, [INFERRED] scan, architectural-surprise halt,
BLOCKED_SPEC_OUTDATED, zero-debt check, dual review. Unblocks reuse
for Áreas 6-9 (Trilho 1).
EOF
)"
```

### Task 7: Re-register the skill

**Files:**
- The skill registration for `area5-microsprint` (location found in Task 5 — likely `.claude/skills/` or a settings entry).

- [ ] **Step 7.1: Update the registration**

Point the skill at `spoke-microsprint.js` and rename it to `spoke-microsprint` (or keep `area5-microsprint` as an alias if Step 6.3 chose alias). Match whatever registration mechanism Task 5 revealed.

- [ ] **Step 7.2: Verify resolvable + commit**

Confirm the skill list (next session) would show `spoke-microsprint`. Commit:

```bash
git add <registration file>
git commit -m "$(cat <<'EOF'
chore(skills): register spoke-microsprint (was area5-microsprint)
EOF
)"
```

**MS3 gate:** `spoke-microsprint.js` parses + validates args; gates intact; skill re-registered; no dangling `area5-microsprint` reference (except historical session logs). `git push`. Update `TODO.md` (MS3 ✅).

---

## Phase MS4 — Live-inspect contract + integration_test gate

Promote the rule that failed twice (trust-no-stale-baseline) from memory into the deterministically-loaded agent contract + checklist, and add the per-area integration_test gate.

### Task 8: Add the live-inspect contract to spoke-parity-checker

**Files:**
- Modify: `.claude/agents/spoke-parity-checker.md`

- [ ] **Step 8.1: Read the agent def, then insert the contract clause**

Read `.claude/agents/spoke-parity-checker.md`. Add a prominent clause (near the top of the operating instructions, not buried) stating:

> **Live re-inspection per feature is mandatory.** A prior-session Spoke baseline — even one that exists, is non-zero bytes, and appears correctly named — is NOT trustworthy. Before any spec is locked or any implementation begins, re-capture the LIVE Spoke state of the specific widget under work on the M54. The MS4 (0-byte capture) and MS5 (mislabeled capture) failures both passed a naive existence/byte check yet were wrong; only re-inspecting the named widget at implementation time catches this. Order of ops: map → live-inspect → implement → validate. Cite screenshot pixels (not XML bounds alone) for any Compose icon claim (`lesson_uiautomator_blindspot_compose_imagevectors`).

- [ ] **Step 8.2: Commit**

```bash
git add .claude/agents/spoke-parity-checker.md
git commit -m "$(cat <<'EOF'
chore(agents): bind live-inspect-per-feature into spoke-parity-checker

Promote the rule that failed in MS4 (0-byte) and MS5 (mislabeled)
from a recalled memory note into the agent's deterministically-loaded
contract: a prior-session baseline is never trustworthy; re-capture
live before locking any spec. Survives session resets.
EOF
)"
```

### Task 9: Add the live-inspect rule + integration_test gate to the checklist

**Files:**
- Modify: `docs/M2-SLICE-CHECKLIST.md`

- [ ] **Step 9.1: Add the live-inspect checkbox**

In §"Antes de qualquer trabalho num slice", add a checkbox:
`- [ ] **Live-inspect no momento da implementação (per ADR-0036 + spoke-parity-checker contract).** Re-capturar o estado LIVE do widget no M54 ANTES de travar spec ou implementar. Baseline de sessão anterior — mesmo existindo, não-zero, e nomeado certo — NÃO é confiável (falhas MS4 0-byte + MS5 mislabeled). Ver [boundary doc] para o que está em escopo (B2C) vs fora (B2B Dispatch).`

- [ ] **Step 9.2: Add the integration_test per-area gate**

In §"Antes de PR", add:
`- [ ] **`integration_test/` on-device (hard gate se mexeu navegação).** Se a área adicionou/alterou rota GoRouter ou comportamento de Android-back, um teste `integration_test/` no M54 é obrigatório antes de declarar a área pronta (widget tests não pegam branch-stack do GoRouter nem Android-back — `lesson_slice_checklist_integration_test_gate`):`
```bash
cd apps/mobile && flutter test integration_test/ -d RQCW401G33T
```

- [ ] **Step 9.3: Verify + commit**

```bash
grep -n "Live-inspect no momento\|integration_test/ on-device" docs/M2-SLICE-CHECKLIST.md
git add docs/M2-SLICE-CHECKLIST.md
git commit -m "$(cat <<'EOF'
docs(checklist): live-inspect rule + integration_test per-area gate

Live-inspect-per-feature becomes a pre-work checkbox; integration_test
on the M54 becomes a hard pre-PR gate for any area touching nav. Both
encode lessons that cost rework (MS4/MS5 stale baseline; MS5 app.dart
scope error).
EOF
)"
```

**MS4 gate:** contract in agent def + checklist; integration_test gate in checklist. `git push`. Update `TODO.md` (MS4 ✅).

---

## Phase MS5 — Thin stubs for Áreas 6–9

Each remaining Spoke-clone area gets a SHORT live-inspect-first stub — NOT a pre-written spec. Each carries an active `[INFERRED — VERIFY BEFORE LOCK]` marker so the workflow preflight HALTS until a real baseline replaces it.

### Task 10: Confirm which areas remain unbuilt

**Files:** none (read-only).

- [ ] **Step 10.1: Read the roadmap's Slice 2 area list**

```bash
grep -nE "^### Área [0-9]" docs/08-ROADMAP-v2.md
```

Confirm which Áreas (6, 7, 8, 9 per CLAUDE.md notes) are unbuilt Spoke-clone areas. The stub set = exactly those. Áreas 1–5 are built (no stub). Slices 4–7 are Track 2 (no stub — they get full specs via brainstorming, not thin stubs).

### Task 11: Write the thin stubs

**Files:**
- Create: `docs/superpowers/specs/2026-06-06-area<N>-stub.md` for each unbuilt clone area.

- [ ] **Step 11.1: Author each stub from this template**

Each stub is short (≈20 lines) and follows this shape:

```markdown
# Spec (stub) — Área <N>: <name> [INFERRED — VERIFY BEFORE LOCK]

> **Date:** 2026-06-06 · **Status:** STUB — live baseline NOT yet captured.
> **Track:** 1 (Spoke-clone). **The Spoke baseline IS the spec.**

## How to execute this area

1. Confirm M54 connected + Spoke logged in.
2. Live-inspect the Spoke screen(s) for this area (per spoke-parity-checker contract — a prior baseline is NOT trustworthy).
3. The captured baseline replaces this stub's [INFERRED] rows.
4. Run `spoke-microsprint.js` with the captured baseline files + this area's `areaSlug`.
5. Honor the B2C/B2B boundary ([boundary doc]): if any screen exposes a Dispatch feature (assign-to-driver, fleet tracking, team mgmt, customer notifications, recipient tracking, analytics), SKIP it — it's B2B.

## What the inventory says (description only — NOT a locked spec)

[INFERRED — VERIFY BEFORE LOCK] <one line pointing at the relevant inventory §10.x for this area>

## Acceptance

Defined at implementation time from the live baseline. Gates: flutter analyze clean, flutter test green, integration_test/ if nav changed, spoke-parity-checker D4, zero tech debt.
```

Fill `<N>`, `<name>`, and the inventory §-pointer per area from the roadmap. Keep the `[INFERRED — VERIFY BEFORE LOCK]` marker ACTIVE (in a table row or as shown) so the workflow preflight halts on it.

- [ ] **Step 11.2: Verify the markers are active**

```bash
grep -rn "INFERRED — VERIFY BEFORE LOCK" docs/superpowers/specs/2026-06-06-area*-stub.md
```

Expected: one active marker per stub.

- [ ] **Step 11.3: Commit**

```bash
git add docs/superpowers/specs/2026-06-06-area*-stub.md
git commit -m "$(cat <<'EOF'
docs(specs): thin live-inspect-first stubs for Áreas 6-9

Each stub leads with "the Spoke baseline IS the spec — inspect live
first" and carries an active [INFERRED] marker so spoke-microsprint's
preflight halts until a real baseline replaces it. Deliberately NOT
pre-written specs (that staleness was the MS4/MS5 failure mode).
EOF
)"
```

**MS5 gate:** one stub per unbuilt clone area, each with an active `[INFERRED]` marker, each citing the boundary doc. `git push`. Update `TODO.md` (MS5 ✅).

---

## Phase MS6 — Cleanup + closure

Confirm `/tmp` clean + guard it; fix the dangling memory pointer; prove no code regressed; write the closure report; open the PR.

### Task 12: Confirm /tmp clean + guard inspection captures

**Files:**
- Modify: `.gitignore` (only if a capture path under the repo isn't already ignored)

- [ ] **Step 12.1: Confirm /tmp is empty**

```bash
find /tmp -maxdepth 2 -path '*spoke-*' 2>/dev/null | head; echo "exit: $?"
```

Expected: no output (already purged by the environment restart). If any `/tmp/spoke-*` resurfaced during this sprint's own work, that's fine to leave in `/tmp` (ephemeral) — the guard is only about the REPO.

- [ ] **Step 12.2: Confirm the repo never versions captures**

```bash
git check-ignore -v /tmp/spoke-x.png 2>/dev/null; grep -nE "spoke-.*\.png|/tmp" .gitignore 2>/dev/null
git ls-files | grep -iE "spoke-.*\.(png|xml)$" | head
```

Inspection captures live in `/tmp` (outside the repo) so they're inherently un-versioned. If `git ls-files` shows ANY committed `spoke-*.png/xml`, remove it (`git rm`) — it shouldn't exist. If the team ever captures under the repo, add a `.gitignore` rule. Default: nothing to change (captures are in `/tmp`).

- [ ] **Step 12.3: Commit only if .gitignore changed**

```bash
git add .gitignore && git commit -m "chore(gitignore): guard against versioning Spoke inspection captures"
# skip if no change needed
```

### Task 13: Fix the dangling memory pointer

**Files:**
- Modify: `docs/decisions/0042-time-picker-numpad-spoke-fidelity.md` (line 53)

- [ ] **Step 13.1: Fix the reference**

Line 53 references `feedback_spec_drafting_requires_live_widget_baseline.md` which never existed. The real memory is `feedback_spoke_evidence_per_ms.md`. Edit line 53 to point there:
`This rule lives operationally in \`~/.claude/projects/.../memory/feedback_spoke_evidence_per_ms.md\`.`

- [ ] **Step 13.2: Verify no dangling ref remains + commit**

```bash
grep -rn "feedback_spec_drafting_requires_live_widget_baseline" docs/ .claude/ 2>/dev/null
# expected: only this plan/spec mention it (as the thing being fixed); ADR-0042 no longer does
git add docs/decisions/0042-time-picker-numpad-spoke-fidelity.md
git commit -m "$(cat <<'EOF'
docs(adr-0042): fix dangling memory pointer

Pointed at feedback_spec_drafting_requires_live_widget_baseline.md
which was never created. Repoint to the real memory file
feedback_spoke_evidence_per_ms.md.
EOF
)"
```

### Task 14: Prove no code regressed

**Files:** none (verification only).

- [ ] **Step 14.1: Full static sweep**

```bash
cd apps/mobile && flutter analyze 2>&1 | tail -3 && flutter test 2>&1 | tail -5 && cd ../..
cd apps/backend && bun run typecheck && cd ../..
```

Expected: analyze ≤ the Phase 0 baseline (~23, no new); test ≥ 249; typecheck exit 0. Since no `lib/`/`src/` was touched, these MUST match the baseline. Any change here means a scope leak — investigate before continuing.

- [ ] **Step 14.2: Confirm zero source files in the whole sprint diff**

```bash
git diff main...HEAD --stat | grep -E "apps/.*/(lib|src)/" && echo "SCOPE LEAK" || echo "clean: docs+harness only"
```

Expected: `clean: docs+harness only`.

### Task 15: Write the closure report + run docs-lint

**Files:**
- Create: `docs/audits/2026-06-06-restructure-closure.md`

- [ ] **Step 15.1: Write the report**

Summarize per-MS outcomes (the same punch-list shape as the Área 5 audit): what shipped, the B2C/B2B verdict (nothing cut — researched clean), the guards now in place, and the no-regression proof from Task 14.

- [ ] **Step 15.2: docs-lint the touched docs**

Run `/docs-lint` (or the manual checks) over the changed docs. Expected: 0 CRITICAL / 0 IMPORTANT for the touched surface. Fix any broken link the boundary-doc/roadmap links introduced.

- [ ] **Step 15.3: Commit**

```bash
git add docs/audits/2026-06-06-restructure-closure.md
git commit -m "docs(audits): restructure closure report — B2C clarity + harness hardening"
```

### Task 16: Update CHANGELOG + session log + open the PR

**Files:**
- Modify: `docs/10-CHANGELOG.md`
- Create: `docs/sessions/2026-06-06-01-restructure-b2c-harden.md` + index entry (if a session log adds non-obvious context)

- [ ] **Step 16.1: CHANGELOG entry**

Add an entry for the restructure (ADR-0044, boundary doc, generalized workflow, contract, two-track, gates).

- [ ] **Step 16.2: adr-guardian on the new ADR**

Dispatch `adr-guardian` against the diff — confirm ADR-0044 is well-formed and the stack-affecting-change rule is satisfied (this sprint changes no stack, so the guardian should pass cleanly).

- [ ] **Step 16.3: Open the PR (sprint end only)**

```bash
gh pr create --base main --head chore/restructure-b2c-harden \
  --title "chore: restructure — B2C clarity + harness hardening" \
  --body "$(cat <<'EOF'
## Summary
- Researched, cited B2C/B2B boundary doc + ADR-0044 (nothing cut — scope already clean)
- Generalized area5-microsprint -> spoke-microsprint (Áreas 6-9 reuse; gates intact)
- Live-inspect-per-feature contract in spoke-parity-checker + checklist (survives resets)
- Two-track execution model + integration_test per-area gate
- Thin [INFERRED] stubs for Áreas 6-9; dangling memory pointer fixed

## Scope discipline
- Zero apps/*/lib or apps/*/src edits (docs + harness only)
- analyze ≤ 23 pre-existing / test ≥ 249 / typecheck clean — unchanged (no code touched)

## Related
- Spec: docs/superpowers/specs/2026-06-06-restructure-b2c-clarity-and-harden.md
- Plan: docs/superpowers/plans/2026-06-06-restructure-b2c-clarity-and-harden.md
- ADR-0044, boundary doc, closure report
EOF
)"
```

**MS6 gate:** /tmp confirmed clean; pointer fixed; no-regression proven; closure report + docs-lint green; PR opened. `git push`. Update `TODO.md` (MS6 ✅, sprint done).

---

## Self-review

The plan author runs this checklist before declaring the plan complete.

**Spec coverage:** every spec section maps to ≥1 task.

- §Context (B2C/B2B research) → Task 1 (boundary doc) + Task 2 (ADR).
- §Decisions Q1 (keep-and-harden) → enforced by rule #2 + §Non-goals (no deletes).
- §Decisions Q2 (nothing to cut) → Task 1/3 (annotate as B2C, don't cut).
- §Decisions Q3 (boundary doc) → Tasks 1, 2.
- §Decisions Q4 (admin = original) → boundary doc + two-track section (Task 4).
- §Decisions Q5 (generalize workflow) → Tasks 5–7.
- §Decisions Q6 (thin stubs) → Tasks 10, 11.
- §Decisions Q7 (integration_test gate) → Task 9.
- §Decisions Q8 (contract in versioned files) → Tasks 8, 9.
- §Goals 1–10 → MS1 (1), MS2 (2,5), MS3 (3), MS4 (4,6), MS5 (7), MS6 (8,9,10).
- §Risks → mitigations live in the relevant tasks (scope rule #2, parse-validate Step 6.2, three-guard contract).
- §Test strategy → Task 14 (regression) + Step 6.2 (workflow parse) + Step 15.2 (docs-lint).
- §Verification gates → MS6 tasks 12–16.

**Placeholder scan:** no `TBD`/`TODO` in step bodies; the `[INFERRED]` markers in MS5 stubs are intentional (the guard), documented as such in the spec's tech-debt note.

**Scope check:** single concern (process/docs restructure), single branch, single PR, zero `lib/`/`src/` edits by construction.

**Type consistency:** ADR number (0044), branch name (`chore/restructure-b2c-harden`), boundary doc path, and workflow name (`spoke-microsprint`) are consistent across all tasks.

The plan is ready.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-06-restructure-b2c-clarity-and-harden.md`. Execute MS-by-MS in a separate session via `superpowers:executing-plans`, with a review checkpoint at each MS gate. MS1 (boundary doc) lands first so the rest has a stable reference. Do NOT open the PR until MS6.
