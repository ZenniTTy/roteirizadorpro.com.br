# ADR-0023: Adopt official Dart & Flutter MCP server for AI assistant symbol resolution

- **Status:** Accepted
- **Date:** 2026-05-24
- **Deciders:** Eduardo
- **Supersedes:** none
- **Related ADRs:** ADR-0002 (Flutter mobile), ADR-0012 (lefthook + Conventional Commits), ADR-0018 (in-loop auto-validation hooks), ADR-0019 (spec-driven templates)
- **Sprint:** M2-AI Harness — Phase 1 (see `SPRINT-M2-AI-HARNESS.md`)

## Context

The Roteirizador Pro harness has matured (CLAUDE.md, ADRs 0001–0022, slice checklist, three Stop-hooks, spec-driven workflow via `superpowers:`, two subagents). The remaining pain point is **API hallucination**: the AI assistant frequently invents or misremembers Flutter / Riverpod / `flutter_map` / `go_router` API surface area, then either fails at compile time (best case — caught by `flutter analyze` or lefthook) or produces subtly wrong code that passes types but breaks at runtime (worst case — caught only by device smoke).

Session 18 (MS-01b, ADR-0022) is the canonical example: the assistant proposed `context.push` as the fix for back-navigation, an answer derived from training-data memory rather than the current `go_router` 14.6.x API + Android 14 `OnBackInvokedCallback` semantics. Three failed iterations later, the real answer (`StatefulShellRoute.indexedStack` with nested children) came from a Context7 query + codewithandrea. The cost: ~2 hours of iteration that a symbol-resolver + local-docs query would have collapsed to one turn.

Research pass on 2026-05-24 (WebSearch + Context7 over `/websites/flutter_dev` + direct fetch of `docs.flutter.dev/ai/*`) surfaced the **official Dart & Flutter MCP server**, shipped as a subcommand of the Dart SDK (`dart mcp-server`) since Dart 3.9. It exposes via MCP to any compatible AI client:

- Analyzer-backed symbol resolution (real method signatures from `.pub-cache/`, not training data).
- `analyze` and `fix` of current project errors.
- Introspect and interact with running Flutter applications (Dart Tooling Daemon).
- `pub.dev` package search + dependency management.
- Test runner + result parser.
- `dart format`.
- Agentic Hot Reload.

Local toolchain check: `dart --version` reports `3.11.5 (stable)` and `flutter --version` reports `3.41.9` — both above the 3.9 prerequisite. `dart mcp-server --help` runs cleanly and lists tool filters (`--tools=all|dart`, `--exclude-tool`, `--log-file`).

This is the single biggest anti-hallucination win available to the project. Adopting it before Phase 1 of slice 2's remaining sub-slices (which depend heavily on `flutter_map`, `geolocator`, and `speech_to_text` — all areas where the assistant has hallucinated before) will compound into every subsequent fase of M2.

## Options Considered

### Option A — Register the MCP server via `claude mcp add --transport stdio dart -- dart mcp-server` (CLI, user scope)

The doc shows this as one of three integration paths. The CLI writes to `~/.claude.json`.

- Pros: one command; no repo files touched.
- Cons: **not versioned in the repo.** Other contributors (and any future fresh session that doesn't run the command) inherit nothing. The MCP becomes implicit project knowledge that lives on a single dev's laptop. **Rejected** — fails CLAUDE.md "Verify Your Work" by making harness state irreproducible across machines.

### Option B — Add `mcpServers.dart` directly to `.claude/settings.json` (first attempt)

Inspired by the doc's Gemini CLI / OpenCode examples which use a `mcpServers` key in their own settings JSON.

- Pros: single file, versioned.
- Cons: **the Claude Code settings.json schema rejects `mcpServers` as an unrecognized field** (discovered at edit time — schema validator blocked the save with the full property list). Claude Code uses a different mechanism: a separate `.mcp.json` at repo root + an `enabledMcpjsonServers` allowlist in `settings.json`. **Rejected** — based on a schema invariant, not a preference.

### Option C (this ADR) — `.mcp.json` at repo root + `enabledMcpjsonServers: ["dart"]` in `.claude/settings.json`

The canonical Claude Code shape (validated against the live settings.json schema):

- `.mcp.json` at repo root declares the server (`type: stdio`, `command: dart`, `args: ["mcp-server"]`).
- `.claude/settings.json` lists `dart` under `enabledMcpjsonServers` so the server is auto-approved in fresh sessions on this repo without per-session "approve MCP?" prompts.

- Pros: both files versioned; reproducible across machines; schema-valid; survives a `git clean -dfx`; isolated from `~/.claude/` user state.
- Cons: two files instead of one. **Accepted** — the separation actually matches Claude Code's mental model (server definition vs project approval) and the cost is trivial.

## Decision

**Adopt Option C.** Commit `.mcp.json` declaring the `dart` MCP server, and amend `.claude/settings.json` with `"enabledMcpjsonServers": ["dart"]`. No global / user-scope changes.

## Version pinning

The Dart MCP server is **shipped with the Dart SDK** (`dart mcp-server` subcommand), not a separately versioned `pub global` package. Effective version is whatever the local `dart --version` reports.

- Current pinned environment: **Dart 3.11.5 / Flutter 3.41.9**.
- Future bumps to the Flutter SDK pin (next time `pubspec.yaml` bumps the `environment.sdk` constraint) implicitly bump the MCP server version. ADR-0015 (M2 plan + libraries) already covers Flutter SDK versioning; no separate pin needed here.

## Consequences

### Positive

- **API hallucination drops to near-zero for installed packages.** The assistant resolves symbols against the project's actual `.pub-cache/`, not training data. Direct mitigation of the MS-01 → MS-01b ratchet documented in ADR-0022.
- **Token economy improves.** Previously the assistant used `Read` on pub-cache files (hundreds of LOC per lookup) or round-tripped to Context7 for what is now a local query.
- **Agentic Hot Reload** becomes available — the assistant can trigger `r` against a live `flutter run` instead of asking the human to reload after each edit.
- **`pub_dev_search` + `add dependency`** mechanizes the "what version of X is current?" step that Phase 5 of slice 2 already requires for `golden_toolkit` (sprint Phase 6).
- **Cross-machine reproducibility** — every contributor / fresh session inherits the MCP via git pull, no per-dev setup.

### Negative

- **One more local process** during a Claude Code session. Trivial cost (idle stdio server until called) but non-zero.
- **MCP failures degrade silently if not surfaced.** If `dart mcp-server` errors at startup (e.g. broken Dart SDK install), the assistant falls back to training-data answers without an obvious warning. Mitigation: Phase 1 smoke test (`/mcp` lists `dart` ✅ + symbol-resolve test) is the canonical post-install verification; documented in `SPRINT-M2-AI-HARNESS.md` §Fase 1.
- **MCP-first discipline must be taught.** Without a guideline, the assistant might continue to `Read` pub-cache or query Context7 out of habit. Mitigation: amend CLAUDE.md "Context7 Mandatory" section with a precedence rule (Dart MCP first for installed packages, Context7 for not-yet-installed or version-shopping).

### Neutral

- The `mcp_flutter` community plugin (visual snapshot) remains under separate evaluation in Phase 5 / ADR-0027. This ADR covers only the official server.

## Rollback

If the Dart MCP server proves unstable or counterproductive:

1. Remove `"enabledMcpjsonServers": ["dart"]` from `.claude/settings.json`.
2. Delete `.mcp.json` (or remove the `dart` entry if other servers were added later).
3. Revert the CLAUDE.md precedence amendment.

Total revert is a 3-file diff with no codebase touch. Zero risk to product code or build pipeline (the MCP server has no compile-time or runtime dependency on the app).

## Verification (smoke test required at install)

1. Run `/mcp` in Claude Code → `dart` shows ✅ connected.
2. Ask the assistant to resolve a symbol from an installed Flutter package via the Dart MCP (e.g. `MapController` from `flutter_map`) — expect a real method list with source path under `~/.pub-cache/`, not a memory recall.
3. `flutter analyze` continues to pass clean (no regression from harness changes).
4. The three Stop-hooks remain silent on a no-op turn (no false positives from the new MCP).

Smoke test results to be captured in the **next** session log after Claude Code restart (Claude Code loads MCP servers at session start; the session that registered the server cannot validate the `/mcp` listing inline). Phase 1 commit body documents the install + the deferred-validation procedure; the next session log appends the actual `/mcp` ✅ output and the `MapController` resolve result.

## References

- `SPRINT-M2-AI-HARNESS.md` (repo root) — sprint canonical playbook, §"Fase 1 — Dart & Flutter MCP server oficial".
- `docs/superpowers/specs/2026-05-24-ai-harness-upgrade-design.md` — Q1 of the spec's Decisions table.
- `docs/superpowers/plans/2026-05-24-ai-harness-upgrade.md` — Phase 1 task decomposition.
- ADR-0018 — in-loop auto-validation hooks (this ADR is the MCP twin of those hooks: hooks fire after, MCP fires before).
- ADR-0022 — `StatefulShellRoute` — the canonical "we hallucinated, then Context7 saved us" incident this ADR aims to prevent.
- Official docs (fetched 2026-05-24):
  - `docs.flutter.dev/ai/mcp-server`
  - `docs.flutter.dev/ai/ai-rules` (updated 2026-01-05)
  - `docs.flutter.dev/ai/agent-skills`
- Anthropic: `code.claude.com/docs/en/mcp` (Claude Code MCP integration model).
- Context7 query: `/websites/flutter_dev` for "AI rules MCP server agent development assistant guidelines" (2026-05-24).
