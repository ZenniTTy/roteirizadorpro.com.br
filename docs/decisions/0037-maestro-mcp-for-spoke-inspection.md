# ADR-0037: Adopt Maestro + Maestro MCP as the structural inspection layer for Spoke parity work

- **Status:** Accepted (Amendment 1 applied 2026-05-26 — see §Amendments)
- **Date:** 2026-05-26
- **Deciders:** Eduardo (cliente Ueslei representative + product owner)
- **Supersedes:** none
- **Related ADRs:** ADR-0010 (clone positioning — legal boundary), ADR-0023 (Dart MCP server — MCP precedent), ADR-0035 (Spoke is the functional source of truth), ADR-0036 (spoke-parity-checker as the functional parity gate)

## Context

ADR-0036 established `spoke-parity-checker` as the proactive functional-parity gate for every slice-2 / slice-3 microsprint and codified its workflow: `adb shell uiautomator dump` + `screencap` from a connected Samsung M54, with the dispatched subagent interpreting the resulting raw XML. That mechanism has shipped two parity reports successfully but exposed two structural limits the white-label restart (Diretiva #13, 2026-05-26 reset) makes load-bearing:

1. **Manual labor scales linearly with surface area.** Producing a dense inventory of every reachable Spoke screen — what the white-label strategy requires upfront so each implementation cycle reads structure from a ground-truth document rather than re-inspecting — means dozens of `adb shell input tap` / `uiautomator dump` rounds, each followed by the agent hand-parsing the dump into a Markdown entry. The current 22-screen sketch in `docs/inventory/2026-05-26-spoke-vs-rotpro.md` took roughly two hours of hands-on session time; expanding to the realistic ~40–60 screens of the full Spoke surface under the same workflow would consume 8–12 hours of synchronous device time across multiple sessions.

2. **Raw XML inflates hallucination risk.** When the agent is handed an XML dump and asked to produce a structural description, the LLM is generating prose between observed leaves of the tree. Most of the time that prose is faithful, but the format invites confident-sounding inference about behavior (gestures, navigation outcomes, animation patterns) that the dump itself does not contain. For an inventory we will then derive a roadmap from — Diretiva #13 explicitly forbids inventing UX where Spoke has an answer — that residual generation step is a real liability.

Maestro 2.6 ships an official MCP server (`docs.maestro.dev/get-started/maestro-mcp`) that exposes the same primitives the bash workflow uses (`launch_app`, `tap_on`, `back`, `inspect_view_hierarchy`, `take_screenshot`, `list_devices`) as MCP tools over STDIO. The hierarchy command returns a structured representation (CSV/JSON with `class`, `resource-id`, `bounds`, `clickable`, etc.) that the agent can paste into the inventory verbatim instead of paraphrasing into existence. Underneath, Maestro talks to the same Android Accessibility framework as `adb shell uiautomator dump` — so the legal posture established in ADR-0010 (runtime UI observation, no decompilation, no asset extraction) is unchanged: the wrapper changes, not what is observed.

The repo already has one MCP precedent (Dart MCP, ADR-0023). Adding a second is mechanically a one-line edit to `.mcp.json` and one entry in `.claude/settings.json`'s `enabledMcpjsonServers`, validated locally with `maestro --version` and (once the session reloads) `/mcp`.

## Options Considered

### Option A — Keep the bash-based workflow as the single inspection path

- Pros: Zero new tools; subagent contract in `.claude/agents/spoke-parity-checker.md` ships as-is; no Java/brew dependency drift on contributors who don't run inventory work.
- Cons: Accepts the 8–12-hour cost of expanding the inventory; preserves the hallucination surface area; forecloses the auto-navigation benefit Maestro provides.
- Cost: Time cost recurring per slice; eventual silent inventory drift as agents accumulate small inferences that no one catches.

### Option B — Replace bash with Maestro entirely (no fallback)

- Pros: Single code path; simplest mental model.
- Cons: Maestro CLI requires Java 17+ and brew on the contributor machine; a session where Maestro fails to launch (driver crash, port conflict, Java upgrade pending) silently loses the parity gate; ADR-0036's existing battle-tested workflow becomes dead code instead of a known-good fallback.
- Cost: Higher operational fragility for marginal simplification.

### Option C — Adopt Maestro as the preferred path; keep bash as the documented fallback (this decision)

- Pros: Captures the productivity and hallucination-resistance gains immediately for inventory-scale work; preserves ADR-0036's mechanism for any session where Maestro is unavailable; both paths observe the same Android Accessibility surface, so the legal boundary is unchanged regardless of which path executes; switching back is a one-line edit if Maestro proves unfit.
- Cons: Two paths in the subagent prompt instead of one; small ongoing cost of keeping both descriptions accurate.
- Cost: ~45 minutes Fase-A setup (Maestro install, MCP wire-up, subagent edit, .gitignore, this ADR) plus a one-time review cadence to confirm the fallback still works whenever the contract evolves.

## Decision

Adopt **Option C**. Maestro CLI (installed via `brew install mobile-dev-inc/tap/maestro --formula`) plus Maestro MCP (wired into `.mcp.json` alongside the existing Dart server) become the **preferred** structural inspection layer for `spoke-parity-checker` and any other future Spoke-touching workflow. The existing `adb shell uiautomator dump` + `screencap` workflow stays in the subagent prompt as an explicitly documented **fallback** to run when `maestro --version` fails, when `/mcp` does not show `maestro ✅ connected`, or when a specific flow exposes a Maestro bug.

The subagent prompt at `.claude/agents/spoke-parity-checker.md` is updated to make the preference machinery-readable: Step 2 (Inspect Spoke) instructs the dispatched agent to verify Maestro availability first and use Maestro tools when available, falling back to the bash path with the verification result captured in the report. Step 3 (Inspect Roteirizador Pro) follows the same pattern. The report's contract (legal guardrails, "must-fix / should-fix / nit" categorization, no microcopy >5 consecutive words, no `git add` of `/tmp/` artifacts) is unchanged.

This decision is policy. Execution lives in the same commit that lands this ADR, on branch `chore/maestro-mcp-adoption`, scoped to: `.mcp.json`, `.claude/settings.json`, `.gitignore`, `.claude/agents/spoke-parity-checker.md`, and this file. No `apps/` code is touched.

## Consequences

- **Positive — inventory work becomes feasible at the right scale.** The white-label roadmap (Diretiva #13) needs the Spoke surface mapped before implementation can proceed at the cadence the strategy implies. Maestro MCP makes a 3–5h single-session pass realistic where the bash workflow forced multi-session synchronous device time.
- **Positive — hallucination surface area shrinks.** Hierarchy output pasted from `inspect_view_hierarchy` is observable fact; the agent's prose around it is bounded to descriptions of structural facts already in the dump. The "neutral structural description" rule in ADR-0036 becomes easier to enforce because the dump now lives next to the description in the same inventory entry.
- **Positive — auto-navigation unlocks state coverage we previously skipped.** Walking every state of the route-active sheet (collapsed / mid / expanded / each bottom-bar input mode) is mechanical for `tap_on` + `inspect_view_hierarchy` but tedious enough by hand that prior inventory passes accepted partial coverage.
- **Negative — new local dependency.** Contributors who run parity work need Maestro CLI installed (brew tap + install, ~5 minutes; ~400MB disk including a bundled JDK). CI/CD is untouched. Contributors who do not run parity work see nothing change.
- **Negative — two paths to maintain in the subagent prompt.** The fallback documentation must stay accurate; a divergence is easy to introduce silently. Mitigated by the verification step at the top of Step 2, which forces every dispatch to record which path it took.
- **Neutral — legal posture unchanged.** Both paths observe runtime UI state through the Android Accessibility framework. Both are bound by ADR-0010 (no decompilation, no asset extraction, original visual identity). The decision is about tooling, not about what is observed.

## Implementation Notes

- Maestro installs as a Homebrew **formula**, not the default cask: `brew install mobile-dev-inc/tap/maestro --formula`. The plain `brew install maestro` resolves to the Maestro Studio desktop app, which does not include the CLI.
- The MCP server is exposed via the `maestro mcp` subcommand. `.mcp.json` invokes it with `MAESTRO_CLI_NO_ANALYTICS=1` set in the server's env to suppress the analytics opt-in banner on every spawn.
- Maestro emits picocli/JNI warnings on every invocation against the bundled OpenJDK 26. These are cosmetic and do not affect output. Hierarchy dumps and tool calls succeed regardless.
- `MAESTRO_CLI_NO_ANALYTICS=1` should also be exported in any contributor shell that runs `maestro` directly outside the MCP context (e.g. ad-hoc `maestro hierarchy` smoke tests).
- The connected Android device is selected with `maestro --udid RQCW401G33T <command>` (the flag attaches to the root, not the subcommand). When the M54 is the only device attached, the flag is optional.
- Working artifacts (screenshots, recordings, transient session state) live in `/tmp/spoke-inspection/` (already covered by ADR-0036's gitignore) and in `~/.maestro/` (developer-machine state, never relevant to commit). Defensive `.gitignore` entries `**/maestro-cache/` and `.maestro/` cover any in-repo write Maestro might attempt.

## References

- Maestro MCP server reference: https://docs.maestro.dev/get-started/maestro-mcp
- Maestro CLI install: https://docs.maestro.dev/getting-started/installing-maestro
- ADR-0010 — clone positioning (legal boundary, unchanged by this decision).
- ADR-0023 — Dart MCP server adoption (precedent for adding a second MCP server alongside `dart`).
- ADR-0035 — Spoke is functional source of truth; prototipo is creative visual reference.
- ADR-0036 — `spoke-parity-checker` functional-parity gate; this ADR amends its Step 2/Step 3 inspection methodology without changing the gate semantics or the report contract.

## Amendments

### Amendment 1 (2026-05-26) — Operational rules learned during Fase B deep-pass

Fase B (dense Spoke inventory pass, see `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §10.1-10.22) surfaced two operational practices that materially improved the quality of the structural extraction and reduced wasted cycles. Both apply to any future `spoke-parity-checker` dispatch and to any Fase-B-like inventory work.

**Rule 1 — Docs > Inferência: when behavior is ambiguous, consult official docs FIRST.**

When tap on a label opens an unexpected screen, when a UI element seems to have dual function, when a picker has non-obvious option semantics, the agent **MUST** first WebSearch / WebFetch the official Spoke / Circuit / Getcircuit documentation (`spoke.com`, `help.spoke.com`, `getcircuit.com`, app store listings, blog) before inferring behavior from the XML dump alone. Then return to Maestro to validate the docs-informed understanding empirically.

Rationale: ambiguous UI elements consume a lot of cycles when explored via trial-and-error tap sequences. A 30-second WebSearch often resolves the ambiguity by surfacing the official feature name, which then makes the tap behavior obvious. Observed in Fase B at §10.6.1 (chip "ID Pendente" mistaken for delivery status — resolved by reading help.spoke.com) and at §10.6.2 (Package ID + Color labels + Load vehicle features confirmed via spoke.com).

Constraint: ADR-0010 boundary preserved — docs are consulted to **understand functionality**, not to copy microcopy. Any text from official docs that the agent paraphrases into the inventory follows the same >5-word-verbatim rule that already applies to XML dumps.

**Rule 2 — Empirical > Docs: when observation contradicts documentation, the observation wins.**

Spoke's official documentation occasionally describes features that are gated by paid plans, region-specific configurations, or settings the current user does not have enabled. When the empirical Maestro observation contradicts what the docs claim, **the empirical observation has precedence** for the inventory entry. The inventory MUST note the divergence explicitly so future implementation decisions know that the docs alone cannot be trusted.

Rationale: docs reflect Spoke's intended product surface; observation reflects what the user actually sees. RotPro replicates user behavior, not intended behavior. Observed in Fase B at §10.14 (docs claimed "Não entregue" opens a failure reason picker with pre-set + custom options; empirical shows direct silent mark + advance, no picker). Implementation deferred picker until empirical confirmation in different conditions.

**Encoding these rules in the subagent prompt:**

`.claude/agents/spoke-parity-checker.md` Step 4 (Compare) gains a new bullet: *"When uncertain about a behavior, consult official Spoke docs via WebSearch before inferring from the XML alone. If docs and observation diverge, observation wins; record the divergence in the report."* This was added in the Fase B PR alongside this amendment.

---
