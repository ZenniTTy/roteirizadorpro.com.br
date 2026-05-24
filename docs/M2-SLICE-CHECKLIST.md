# M2 Slice Execution Checklist

> Use this checklist for **every** M2 slice from slice 2 onward. The format is intentionally rigid — slice 1 wasted ~45 minutes diagnosing a missing INTERNET permission because we skipped the `aapt2 dump permissions` verification step. Each box below exists because of a real past failure or a real future risk.
>
> Process skill applies: when invoking, use `superpowers:brainstorming` BEFORE the implementation step the first time the slice is touched in a new chat.

## Pre-flight — before writing any code

- [ ] **Read** `CLAUDE.md`, `docs/08-ROADMAP.md` (the slice's section), `docs/M2-COST-MODEL.md`, `TODO.md`, the last 5 entries in `docs/sessions/0001-INDEX.md`. If you skip this you will re-derive decisions and contradict prior ADRs.
- [ ] **Re-read the prototype files** matching the slice (e.g. for slice 2, `prototipo/screens-a.jsx` through `screens-e.jsx`). The prototype is the canonical UI source per `docs/decisions/0010-clone-positioning.md`.
- [ ] **Validate every external library** the slice introduces against Context7 (`resolve-library-id` → `query-docs`). Mandatory for any package within the cutoff window. Capture the version pin you intend to use.
- [ ] **Confirm there are no in-progress PRs** that conflict: `gh pr list --state open`. If there are, decide whether to merge them first or coordinate.
- [ ] **`git status` on `develop` is clean** and you are aligned with `origin/develop`. If not, fix the divergence before branching.
- [ ] **Brainstorm.** Even when the slice section in the ROADMAP looks complete, run `superpowers:brainstorming` with the user before opening files. Surfaces hidden requirements early.

## Branch and naming

- [ ] Branch: `feat/m2-slice-N-<kebab-topic>` off `develop`. Example: `feat/m2-slice-2-telas-core`.
- [ ] Commit format: Conventional Commits. The scope-enum in `commitlint.config.cjs` lists the allowed scopes — if your slice needs a new scope, add it in the same PR.
- [ ] One **logical change per commit**. Don't bundle "add map widget + change auth flow" into one commit. Lefthook + commitlint enforce part of this; the rest is your judgment.

## Scope and contracts (schema source-of-truth, ADR-0013)

- [ ] **TypeBox schema first.** Every new HTTP endpoint declares its request/response in `apps/backend/src/<feature>/schemas.ts`. Even if the slice is mobile-only, define the schema for the endpoints you'll consume from the mobile.
- [ ] **Dart DTO mirror.** Every Dart DTO file starts with `// Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>` (single-DTO) or `... -> {Schema1, Schema2, ...}` (multi-DTO), ASCII `->` only, no backticks (ADR-0020). Fields and types match 1:1; no renames.
- [ ] **Prisma migration only when the slice changes persistent storage.** Never expose `@prisma/client` rows from a handler — always whitelist via a TypeBox response schema.
- [ ] **ADR for any new library, new external service, or non-trivial new pattern.** Format follows `docs/decisions/0000-template.md`. The adr-guardian agent should report `clear to commit` on the slice's diff.

## Implementation discipline

- [ ] **Default to writing no comments.** Only explain WHY, never WHAT (the names already say WHAT).
- [ ] **Surgical edits only.** Don't refactor adjacent code unless the refactor is the slice's purpose. CLAUDE.md "Karpathy 4 principles."
- [ ] **No backwards-compat shims**, feature flags, or "for future use" hooks unless the slice itself needs them.
- [ ] **Hot reload over hot restart over full restart** when iterating on Flutter (`CLAUDE.md` "Flutter Hot-Reload Discipline").
- [ ] **The build script does the build.** Run `bash apps/mobile/scripts/build-release-apk.sh` instead of memorizing flags.

## Verification — required before claiming "done"

- [ ] `flutter analyze` clean.
- [ ] `flutter test` passes (widget tests at minimum for new screens).
- [ ] **Dispatch `flutter-perf-auditor` (ADR-0027)** against the slice's touched mobile files. Resolve every `must-fix` before merge; document any deliberately-skipped `should-fix` in the slice doc with a one-line rationale. Nits are advisory. The auditor is read-only — its output is a punch list, not a code change.
- [ ] `bun run typecheck` clean in the modified apps (`apps/backend/`, `apps/landing/`).
- [ ] `bun run lint` clean in the landing.
- [ ] **`aapt2 dump permissions <built APK>`** if Android permissions changed — verify the expected `android.permission.*` entries are all present. **This is the slice 1 lesson.** Path: `~/Library/Android/sdk/build-tools/<latest>/aapt2`.
- [ ] **`apksigner verify --verbose --print-certs <built APK>`** confirms v2 signature scheme and the cert SHA-256 matches the keystore (`D9:C9:61:D6:A3:2A:0C:45:B6:11:E0:E1:2D:86:FA:7E:52:1C:D3:3C:88:83:3C:7C:5D:5A:B9:91:9F:E9:14:31`).
- [ ] **Manual end-to-end** on a real Android device (Samsung Galaxy A06 currently); install via `adb install -r <apk>`, exercise the slice's golden path, capture a screenshot for the PR body.
- [ ] **HARD GATE — device fidelity sweep (ADR-0021).** Before PR open, every screen exercised in the device E2E above must visually match its `Screen*` counterpart in `prototipo/screens-*.jsx`. The session-17 slice-2 audit proved that `flutter analyze` + `flutter test` + static `prototype-fidelity-checker` can pass while the device still ships 4 Criticals on a single screen. The fix: capture a screenshot per E2E step, file it under `docs/sessions/<slice-session>/screenshots/`, and either (a) eyeball it against the prototype OR (b) dispatch `prototype-fidelity-checker` on each touched Dart file. Any Critical found here blocks the tag — slip the tag date, don't skip this gate.
- [ ] **HARD GATE — `flutter test integration_test/` must pass on a connected Android device** for any slice that touches `apps/mobile/lib/app.dart` or modifies a navigation expression (`context.go`, `context.push`, `context.pop`, `goBranch`, etc.). This gate exists because the slice-2 MS-01 regression passed widget tests + analyze + fidelity-checker + code-reviewer and still shipped a back-navigation bug on the device — see ADR-0022.
- [ ] **Curl evidence** for any new backend endpoint. Paste the `curl -i` output into the PR body. No "trust me, it works."

## Version bumping

| Change | semver delta | Build code (`+N`) |
|---|---|---|
| New screen / UI tweak / dep update without behavior change | patch (`1.0.X`) | +1 |
| New user-facing feature (slice 2, slice 5, slice 7) | minor (`1.X.0`) | +1 |
| Breaking API change (slice 4 payments) | bump major if pre-1.0; we are post-1.0 so it's a deliberate decision in the slice's ADR | +1 |

`versionCode` (`+N`) **always increments**, even when `versionName` doesn't. Android refuses installs of an APK whose `versionCode` is ≤ the installed one.

## PR workflow

- [ ] Push the branch to origin.
- [ ] Open the PR `feat/m2-slice-N-<topic>` → `develop` using `gh pr create`. **Template the body:**

  ```markdown
  ## Summary
  <2-4 bullets — what the user sees changed>

  ## What this slice ships (vs develop)
  - <high-level deliverables>

  ## Test plan
  - [x] flutter analyze / test
  - [x] aapt2 dump permissions
  - [x] apksigner verify
  - [x] adb install + golden-path manual test on Galaxy A06 (screenshot attached)
  - [x] backend curl evidence
  - [ ] Vercel preview deploy (URL auto-comment by Vercel bot)

  ## Pre-merge manual action
  <if any — e.g. 1Password backup for slice 1>

  ## Related
  - Slice N section of docs/08-ROADMAP.md
  - ADR-XXXX (new in this PR)
  - Session log docs/sessions/YYYY-MM-DD-NN-<topic>.md
  ```

- [ ] **Vercel preview check is SUCCESS** before requesting review.
- [ ] After merge to `develop`: open the **promotion PR** `develop` → `main` (matches the slice-1 pattern via PR #4). One promotion PR per slice keeps the production deploy story clean.
- [ ] After merge to `main`: tag `vX.Y.Z` with an annotated tag, push the tag, sanity-check the apex serves the new asset/page.

## Post-merge

- [ ] **Republish APK** in `apps/landing/public/` with the new versioned filename if the slice changes the mobile build. Update the four CTAs in `apps/landing/src/app/page.tsx` (or read from a shared constant).
- [ ] **Smoke-test in production.** `curl -sI https://roteirizadorpro.com.br/<changed-asset>`. Open the home in a browser.
- [ ] **Capture a screenshot** of the production state and attach to the merged PR.
- [ ] **Session-end protocol** (`docs/sessions/0000-template.md` → `docs/sessions/YYYY-MM-DD-NN-<topic>.md`). Update `docs/sessions/0001-INDEX.md` and `TODO.md` in the same commit. Use the `/session-end` slash command.
- [ ] **Update `docs/10-CHANGELOG.md`** with one entry for the slice.
- [ ] **Mark the slice's section in `docs/08-ROADMAP.md` as ✅ shipped** with the tag and date.

## When something goes wrong

- **Don't panic-revert.** Investigate the root cause; a destructive `git reset` or `git push --force` to a public branch in this project is forbidden unless the user explicitly asks (CLAUDE.md "Git Protocol").
- **Don't bypass hooks** (`--no-verify`). Lefthook + commitlint exist to catch the small things. If a hook fails, fix the underlying issue.
- **Don't bypass the build script.** If `flutter build apk` works manually but the script fails, the script is the bug — fix the script, don't bypass it.
- **Write the gotcha into memory.** A real failure that future sessions could repeat goes into `~/.claude/projects/.../memory/<kebab-name>.md` as a `feedback` memory. See the slice 1 example: `flutter-android-release-internet-permission.md`.

## Cost-conscious choices (per slice)

Every architectural decision must answer "does this push the monthly infra cost above the ceiling in `docs/M2-COST-MODEL.md`?" If yes, justify in an ADR or find a cheaper path. Examples of choices that already passed this gate:

- Tile provider: public OSM tiles (free) instead of Mapbox (paid above 50k loads/month).
- VRP solver: in-process Node TS implementation instead of paid GraphHopper Directions API or jsprit JVM.
- Geocoder: public Nominatim instead of Google Geocoding API.
- Hosting: Vercel free tier for landing + admin instead of a second managed instance.
- Database backup: local `pg_dump` cron instead of paid S3 / R2 / Vercel Blob.

If the project crosses meaningful user thresholds (50 paying users; 500 paying users), revisit each of these in a fresh ADR.

## Glossary of slice-affecting docs

- **`prototipo/`** — canonical UI. Visual identity, screens, gestures, flows must match 1:1. Tokens in `prototipo/tokens.js` are canonical.
- **`docs/08-ROADMAP.md`** — what we're building, in what order, what "done" means.
- **`docs/M2-COST-MODEL.md`** — cost ceilings.
- **`docs/decisions/`** — every stack-affecting decision lives here. New libraries → new ADR.
- **`docs/04-FEATURES.md`** — the feature catalogue. Loose contract with the client; update if a slice changes how a feature works.
- **`docs/05-SCREENS.md`** — screen catalogue. Update each slice with which screens shipped.
- **`docs/02-ARCHITECTURE.md`** — architecture and data flow. Update when a new endpoint or service joins.
- **`apps/backend/src/<feature>/schemas.ts`** — the only place HTTP contracts are defined.
- **`apps/mobile/lib/features/<feature>/data/dto/*.dart`** — the only place mobile DTOs live. Header comment binds each file to its TypeBox source.
