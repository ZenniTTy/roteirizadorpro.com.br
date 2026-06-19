---
trigger: glob
---

<!--
Activation: Glob (intended) — pattern: apps/**/*.{ts,tsx,dart,prisma}, package.json, pubspec.yaml
Confirm in Antigravity UI: Customizations → Rules → this file → set "Glob" with the pattern above.
If Glob mode is not supported via UI, fall back to "Model Decision".
-->

# External Knowledge Precedence (Dart MCP → Context7 → Training Data)

Before proposing or installing any external library/framework, follow this precedence — strictly in order:

## 1. Dart MCP first (for Dart/Flutter)

For any symbol, class, or method from a Dart/Flutter package **already installed** in `apps/mobile/pubspec.yaml` (resolvable from local `.pub-cache/`), use the Dart MCP tools (`resolve_symbol`, `analyze`, `hover`, etc.) instead of reading pub-cache files or hitting Context7.

The MCP returns the real signature from the local analyzer — zero hallucination, zero token spent on file traversal.

Verify the Dart MCP is connected: in Antigravity, the MCP server should be discoverable from `.mcp.json`. If unsure, ask the operator to confirm. Required: Dart ≥ 3.9 (currently 3.11.5 per CLAUDE.md). See ADR-0023.

## 2. Context7 second

For any library not yet installed, or to confirm the current pub.dev / npm version before adding a dependency, or for any non-Dart library (Fastify, Prisma, TypeBox, Next.js, Riverpod, go_router), Context7 is **mandatory**.

Training-data knowledge has a cutoff; Context7 has current docs. **No exceptions for libraries within reach of the cutoff date.**

Two-step: `resolve-library-id` → `query-docs`.

## 3. Training data third (rarely)

Only for stdlib and stable APIs (HTTP verbs, SQL syntax) where the answer hasn't changed in years.

## Maestro MCP for Spoke inspection

When inspecting Spoke (the reference app for behavior parity per ADR-0035 + ADR-0037), use the Maestro MCP tools (`mcp__maestro__inspect_view_hierarchy`, `tap_on`, `back`, `launch_app`, `take_screenshot`, `list_devices`) on Eduardo's connected Samsung M54.

Fallback when Maestro is unavailable: `adb shell uiautomator dump` + `adb shell screencap`. Same Android Accessibility surface, same legal posture (runtime UI state observation, no decompilation).

Record the chosen path in any Spoke inspection report: `Inspection path: Maestro MCP` or `Inspection path: bash + uiautomator`.

## MCP servers configured for this repo

See `.mcp.json` in the repo root. Currently:

- `dart` — Dart & Flutter MCP server (ADR-0023)
- `maestro` — Maestro CLI 2.6 MCP integration (ADR-0037)

If `/mcp` (or the Antigravity equivalent) does not show both servers connected, surface this to the operator before proceeding with tasks that depend on them.
