# 2026-05-24-20 — M2-AI Phase 1: Dart & Flutter MCP server

## Metadata

- **Date**: 2026-05-24 (America/Sao_Paulo)
- **Sequence**: 20
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: M2-AI sprint Phase 1 — adopt official Dart & Flutter MCP server
- **Duration**: ~1h
- **Related ADRs**: ADR-0023 (new) — Adopt official Dart & Flutter MCP server
- **Related TODO items**: Phase 1 of "Sprint M2-AI (Harness upgrade)" section

## Goal of the Session

Execute Phase 1 of the M2-AI harness sprint: register the official Dart & Flutter MCP server (shipped as `dart mcp-server` subcommand since Dart 3.9) into the project harness so the assistant resolves Flutter / Riverpod / `flutter_map` / `go_router` symbols against the local analyzer instead of hallucinating from training data.

## What Was Done

- Verified local toolchain: Dart 3.11.5 (stable, 2026-04-15) and Flutter 3.41.9 — both well above the ≥3.9 prerequisite.
- Queried Context7 (`/websites/flutter_dev`) for current install instructions; received the canonical Dart MCP doc page showing three config formats (Gemini CLI, OpenCode, Claude Code).
- Attempted first integration via `mcpServers` key in `.claude/settings.json` (Gemini-style format from the doc). **Schema validator rejected the field** with the full property list — Claude Code's settings.json schema does not accept top-level `mcpServers`. Discovered via the harness validator that the canonical Claude Code shape is `.mcp.json` at repo root + `enabledMcpjsonServers` allowlist in `settings.json`.
- Created `.mcp.json` at repo root declaring `dart` server (type: stdio, command: `dart`, args: `["mcp-server"]`).
- Amended `.claude/settings.json` adding `"enabledMcpjsonServers": ["dart"]` — schema-valid, hooks block untouched.
- Smoke-tested `dart mcp-server --help` — exit 0, lists real flags (`--tools=all|dart`, `--exclude-tool`, `--dart-sdk`, `--flutter-sdk`, `--log-file`).
- Authored ADR-0023 — full Options Considered (A: CLI user-scope rejected for non-reproducibility; B: `mcpServers` in settings.json rejected by schema; C: `.mcp.json` + allowlist accepted), Decision, Version pinning (server ships with Dart SDK, no separate pin), Consequences (positive: anti-hallucination + token economy + agentic hot reload + cross-machine reproducibility; negative: extra local process + silent failure mode if MCP crashes + MCP-first discipline must be taught), Rollback (3-file revert, zero risk to product code), Verification procedure (smoke test requires session restart), References.
- Updated CLAUDE.md (3 edits): bumped `Last updated` to 2026-05-24; added 2 rows to Executable Commands table (`dart mcp-server --help` + `/mcp`); extended §"Context7 Mandatory" with a 3-tier precedence rule (Dart MCP first for installed packages, Context7 second for not-yet-installed or non-Dart libs, training-data third for stable stdlib only) plus fallback instruction when MCP unavailable.
- Updated docs/sprints/2026-05-24-m2-ai-harness.md Phase 1 section: marked status ✅; added "Descobertas durante a execução" subsection with three lessons (Gemini-style `mcpServers` rejected; server is SDK-embedded not a separately activated package; smoke test requires session restart); updated gate-de-aceite checklist with 5 done items and 2 deferred-to-human items (the `/mcp` listing + symbol-resolve smoke test, both gated by restart).
- Updated TODO.md: marked Phase 0 ✅ (catching up from previous session, with commit refs) and Phase 1 ✅ with full discovery narrative.
- Authored this session log; index update in same commit.

## Decisions Made

1. **`.mcp.json` + `enabledMcpjsonServers` over Gemini-style `mcpServers` in settings.json** (ADR-0023 Option C). Schema-driven: settings.json validator rejected the alternative. Trade-off: two files instead of one, but cleaner separation between declaration and approval.
2. **Project scope, not user scope.** Both `.mcp.json` and the `enabledMcpjsonServers` allowlist live in the repo, versioned. Any contributor / fresh session inherits the MCP via `git pull` — no per-dev setup. CLI alternative (`claude mcp add`) writes to `~/.claude.json` outside the repo and was rejected.
3. **No separate version pin for the MCP server.** It ships with the Dart SDK; the Flutter SDK pin in ADR-0015 transitively pins it. No `dart_mcp_server` package to `pub global activate` (plan draft assumed this; corrected during execution).
4. **MCP-first precedence rule added to CLAUDE.md.** Without this, the assistant would continue habitual `Read`-of-pub-cache or Context7 for Dart symbols out of muscle memory. Rule makes the new flow explicit and orders fallbacks.
5. **Smoke test (`/mcp` listing + symbol resolve) deferred to next session.** Claude Code loads MCP servers at session start; no way to validate inline in the session that registered the server. ADR-0023 documents the verification procedure; gate-de-aceite items flagged as human-validated.

## Open Questions Left

- [ ] (Next session) Confirm `/mcp` lists `dart` as ✅ after Claude Code restart. If not, troubleshoot: check `.mcp.json` validity, confirm `dart` binary in PATH for Claude Code's spawning context, inspect Claude Code logs.
- [ ] (Next session) Run the symbol-resolve smoke test: ask the assistant to resolve `MapController` from `flutter_map` via Dart MCP and confirm the source path points to `~/.pub-cache/`, not a generic memory recall.

## Files Changed

**Created**:
- `.mcp.json` (root) — Dart MCP server declaration.
- `docs/decisions/0023-dart-flutter-mcp-server.md` — ADR.
- `docs/sessions/2026-05-24-20-phase-1-dart-mcp-server.md` — this file.

**Modified**:
- `.claude/settings.json` — added `enabledMcpjsonServers: ["dart"]`.
- `CLAUDE.md` — bumped Last updated; added 2 rows to Executable Commands; extended Context7 Mandatory with MCP-first precedence rule.
- `docs/sprints/2026-05-24-m2-ai-harness.md` — marked Phase 1 ✅; added Descobertas subsection.
- `TODO.md` — marked Phase 0 ✅ (catch-up) and Phase 1 ✅ with discovery narrative.
- `docs/sessions/0001-INDEX.md` — new entry for session 20.

**Deleted**: none.

## Commits Pushed

```
(pending — Phase 1 lands in one commit at the end of this session)
```

## Hand-off Notes for Next Session

- **Branch:** `feat/m2-ai-harness` (4 commits ahead of `feat/m2-slice-2-telas-core`: `4b528f8`, `baaea44`, `782eb99`, plus the upcoming Phase 1 commit).
- **First action on next session start:** run `/mcp` and confirm `dart` shows as ✅ connected. If yes, ask: "Use the Dart MCP to resolve symbol `MapController` from `flutter_map` and list its public methods." Expect a real method list with source path under `~/.pub-cache/`. If no, troubleshoot before proceeding to Phase 2.
- **Next phase:** Phase 2 — `riverpod-codegen-runner` PostToolUse hook (ADR-0024). The hook gets to leverage the now-active Dart MCP for symbol verification in its smoke test.
- **Slice 2 still unblocked:** sprint branch remains orthogonal. Do not merge until at least Phase 7 closes.
- **Pre-existing untracked items on the branch** (carried from `feat/m2-slice-2-telas-core` tip): `CONTINUATION-PROMPT.md`, `infra/docker-compose.yml` modified, `infra/graphhopper/extract-sp.sh` modified. Not this sprint's responsibility.
- **CLAUDE.md precedence rule now active:** for any Dart/Flutter symbol lookup, the assistant must try Dart MCP first; only fall back to Context7 if MCP is down. Watch for habitual `Read`-of-pub-cache regressions.

## Reference Material Used

- Context7: `/websites/flutter_dev` queried for "Dart MCP server installation activate settings.json Claude Code configuration" (2026-05-24, returned the canonical install doc with all 3 client formats).
- Official Flutter docs: `docs.flutter.dev/ai/mcp-server`, `docs.flutter.dev/ai/ai-rules`, `docs.flutter.dev/ai/agent-skills`.
- Claude Code settings.json schema (returned inline by the validator when the wrong field was attempted) — confirmed `enabledMcpjsonServers` is the canonical mechanism.
- Repo: previous ADR-0022 (the `StatefulShellRoute` saga) cited as the canonical "we hallucinated" incident this ADR aims to prevent.
- Repo: ADR-0018 (in-loop auto-validation hooks) cited as the temporal twin (hooks fire after edits; MCP fires before edits).
