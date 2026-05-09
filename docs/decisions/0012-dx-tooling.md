# ADR-0012: Adopt Lefthook + Commitlint + Commitizen and a Shared VS Code Workspace

- **Status:** Accepted
- **Date:** 2026-05-08
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0011 (Bun for install)

## Context

Phase 1 of M1 is complete and Phase 2 work has started. Two friction points became visible during the Login + Register screens delivery:

1. **The `flutter run` process was killed and restarted on every change**, including for trivial `lib/**.dart` edits. Flutter offers hot reload (sub-second) and hot restart (~2s) via the running `flutter run` (`r` / `R` keystrokes) or via the VS Code Flutter extension's "format on save → hot reload" behavior. Restarting the whole APK build is only required for `pubspec.yaml` asset/dep changes or native code changes. Without an explicit convention, agents and humans reach for the heavy hammer.
2. **No commit-time guardrails.** Conventional Commits is the policy ([CONTRIBUTING.md](../../CONTRIBUTING.md)), but nothing enforces it. A developer can land `wip`, a 200-line commit with no scope, or a commit whose body fails CI.

The official Flutter docs and the 2026 Brazilian/global Node monorepo industry trend converge on the same recommendation:

- For Git hooks: Lefthook over Husky. A single Go binary, single `lefthook.yml`, parallel job execution, language-agnostic, idiomatic for monorepos that mix Node and non-Node toolchains (we have Flutter alongside Bun + Node). Husky has been superseded for new projects since ~2024.
- For commit-message validation: `@commitlint/cli` + `@commitlint/config-conventional`.
- For commit composition: `commitizen` + `cz-conventional-changelog` (gives `bun run commit` an interactive wizard).
- For shared editor config: `.vscode/extensions.json` and `.vscode/settings.json.example` committed; `.vscode/settings.json` itself is git-ignored so each developer can override.

The cost of these is small (~80 MB of `node_modules` at the repo root, one new ADR, one root `package.json`). The benefit is large: `bun run commit` produces a valid Conventional Commit, every commit pre-runs typecheck/lint scoped to the changed app, and every contributor opens the project with the same Dart + TypeScript + Tailwind formatters.

GitHub Actions CI is a separate ADR-worthy decision but follows the same direction; it lands in this commit set as a minimal workflow without its own ADR (it does not change the stack — only verifies it on PR).

## Options Considered

### Option A — Husky + lint-staged (legacy)

- Pros: Most documented in older tutorials. Anyone who's seen a JS project in the last decade has seen Husky.
- Cons: Slow start (Node-based), separate `lint-staged` config, no native parallelism, no language-awareness for monorepos. Husky's own roadmap and the Evil Martians comparison conclude Lefthook is the better successor.

### Option B — Lefthook + commitlint + commitizen (this ADR)

- Pros: Single Go binary; `lefthook.yml` is the only config; `parallel: true` runs jobs concurrently; `glob:` + `root:` per job scopes commands to the changed app; language-agnostic so the same hook can call `flutter analyze` and `bun run typecheck` from different roots; commitlint guarantees Conventional Commits machine-checked; commitizen makes `bun run commit` an interactive wizard so even a tired developer at 3 AM lands a clean message.
- Cons: One more dep at the repo root; Lefthook has a 2.x major (released early 2026), still close to the bleeding edge; new tool for anyone who's only seen Husky.

### Option C — No git hooks, rely on CI alone

- Pros: Zero local install. The simplest possible workflow.
- Cons: Bad commits land before CI catches them, polluting history. Conventional Commits drift over time. Pre-PR friction (a typo in `feat(): ` returns from CI 4 minutes later instead of being fixed at the keyboard immediately). For a solo-dev-plus-AI-agents project this is exactly the kind of mistake that compounds.

### Option D — Per-IDE plugins only (no shared workspace files)

- Pros: Each developer keeps their own preferences.
- Cons: We literally have one developer plus AI agents, but the AI agents read `.vscode/` and `extensions.json` to know what to do. Not committing them means every agent rediscovers them.

## Decision

Adopt **Lefthook 2.x** as the Git hook manager, **`@commitlint/cli` + `@commitlint/config-conventional` 20.x** for commit-message validation, **`commitizen` + `cz-conventional-changelog`** for `bun run commit`, and **shared VS Code workspace files** (`.vscode/extensions.json` committed; `.vscode/settings.json.example` committed; user's own `.vscode/settings.json` stays git-ignored).

The pinned versions (verified against `npm view` on 2026-05-08) and their roles:

| Package | Version | Role |
|---|---|---|
| `lefthook` | `^2.1.6` | Git hook orchestration |
| `@commitlint/cli` | `^20.5.3` | Validate `commit-msg` |
| `@commitlint/config-conventional` | `^20.5.3` | Conventional-Commits ruleset |
| `commitizen` | `^4.3.1` | Interactive `bun run commit` |
| `cz-conventional-changelog` | `^3.3.0` | Adapter Commitizen ↔ Conventional |

Add a minimal root `package.json` (private, no workspace) that holds these dev deps and provides:

- `prepare` script → `lefthook install` (Bun runs `prepare` after install).
- `commit` script → `cz` (the commitizen entry point).
- `engines` declaring `bun >= 1.3` and `node >= 20.9 < 21` (matches ADR-0011 + ADR-0003).

GitHub Actions CI is added in the same commit set as `.github/workflows/ci.yml`, with three independent jobs (`backend`, `landing`, `mobile`) each running `bun install --frozen-lockfile` (or `flutter pub get`), then the app's typecheck/build/analyze. CI does not need its own ADR — it is operational tooling that mirrors what local hooks do, only against `main`/`develop`/PR.

## Consequences

- **Positive:** every commit runs typecheck + lint scoped to the changed app; commit-message format is enforced before the message lands in history; `bun run commit` walks any contributor through the message; GitHub Actions enforces the same checks on PR; every developer opens the project with the same recommended extensions and formatters; the AI agent's hot-reload guidance is now codified in CLAUDE.md so neither I nor a future agent will keep restarting the APK on trivial edits.
- **Negative:** root `node_modules` exists (~80 MB); `bun install` at root must be run once after cloning; one more ADR to maintain.
- **Neutral:** `.git/hooks/*` are now managed by Lefthook — manual edits to those files would be overwritten on the next `lefthook install`.

## Implementation Notes

- `lefthook.yml` lives at the repo root. Pre-commit jobs use `glob:` + `root:` to run typecheck/lint only when files of the matching app changed.
- Pre-commit jobs run in parallel (`parallel: true`).
- `commit-msg` runs `bunx commitlint --edit {1}`.
- Pre-push is intentionally **not** configured yet — we have no Vitest tests in `apps/backend/` and `flutter test` already runs on the developer's machine when they push from VS Code; adding pre-push before there are real tests is friction without value. Re-evaluate when M2 starts.
- `bun run commit` runs `cz` which prompts for type, scope (constrained by `commitlint.config.cjs` `scope-enum`), subject, body and footer.
- The `scope-enum` rule mirrors the commit-scope table in `docs/Blueprint.md` (mobile, backend, landing, infra, auth, routes, …) so an unknown scope is rejected.
- `.vscode/extensions.json` recommends Dart, Flutter, ESLint, Prettier, Prisma, Tailwind. `.vscode/settings.json.example` documents the format-on-save and `dart.flutterHotReloadOnSave: always` settings every developer should have.
- `.vscode/settings.json` itself stays git-ignored (`.gitignore` rule existed before this ADR).

## Boundary: Claude Code hooks vs Lefthook

The repo already has `.claude/hooks/` (`block-env.sh`, `format-dart.sh`) — those are **Claude Code agent hooks**, fired by the Claude Code CLI in response to agent tool calls (e.g., `PreToolUse: Bash`, `PostToolUse: Edit`). They live alongside `.claude/{settings.json,agents,skills}`, are committed, and are Anthropic-specific.

Lefthook hooks (`pre-commit`, `commit-msg`) are **Git hooks**, fired by `git` itself for any contributor regardless of tool — agent or human, VS Code or terminal.

The two systems coexist by design:

| Layer | Lives in | Audience | Triggered by | Examples |
|---|---|---|---|---|
| Claude Code agent hooks | `.claude/hooks/*.sh` registered in `.claude/settings.json` | Only when an agent runs in this repo | Agent tool calls (Bash, Edit, Write, …) | `block-env.sh` (refuse to read .env), `format-dart.sh` (run `dart format` after Dart edits) |
| Git hooks (Lefthook) | `lefthook.yml` at repo root | Every contributor | `git commit`, `git push` | typecheck, lint, commit-msg validation |

Rule: never duplicate logic across the two. If a check belongs at "any commit by anyone", it goes to Lefthook. If a check belongs at "any agent action", it goes to `.claude/hooks/`. A Dart formatter can live in `.claude/hooks/` because we want it on every agent edit; running `flutter analyze` on staged Dart files at commit time belongs to Lefthook because human commits also need it.

## Hot-reload and dev workflow guidance (consequence)

For Flutter, do not kill `flutter run` for changes inside `lib/**`. Three levels:

| Level | Trigger | Cost | When |
|---|---|---|---|
| Hot reload | `r` in the `flutter run` terminal, or VS Code save with `dart.flutterHotReloadOnSave: always` | sub-second, preserves state | Widget edit, color change, copy change, method body. |
| Hot restart | `R` in the same terminal | ~2 s, loses state | New top-level provider, new route, change to `main()`. |
| Full restart (`flutter run` again) | kill + relaunch | 2–7 min (Gradle, install) | `pubspec.yaml` asset/dep change, native (Kotlin/Swift) code change, AndroidManifest change. |

CLAUDE.md gains a section codifying the rule so AI agents do not default to full restart.

## References

- Evil Martians — *Saying Goodbye to Husky: How Lefthook Supercharged Our TypeScript Workflow* (`https://dev.to/saltyshiomix/saying-goodbye-to-husky-how-lefthook-supercharged-our-typescript-workflow-35c8`).
- Evil Martians — *5 cool ways to configure Lefthook* (`https://evilmartians.com/chronicles/5-cool-and-surprising-ways-to-configure-lefthook-for-automation-joy`).
- commitlint docs (`https://commitlint.js.org/`).
- Flutter docs — JSON serialization with `dart run build_runner watch` (`https://docs.flutter.dev/data-and-backend/serialization/json`).
- Flutter docs — *How do I perform a hot reload?* (`https://docs.flutter.dev/flutter-for/react-native-devs`).
- Context7: `/evilmartians/lefthook` and `/websites/flutter_dev` (consulted on 2026-05-08).
