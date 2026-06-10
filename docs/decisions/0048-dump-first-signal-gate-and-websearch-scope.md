# ADR-0048: Dump-first becomes a signal-only harness gate; websearch/Context7 scoped to libraries, not Spoke behavior

- **Status:** Accepted
- **Date:** 2026-06-10
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0018 (in-loop auto-validation hooks), ADR-0036 (spoke-parity-checker gate), ADR-0037 (Maestro MCP), ADR-0045 (static dump baseline — the method this enforces), ADR-0047 (the MS that proved the value: the dump answered the FTUE-gate question, no runtime needed)

## Context

ADR-0045 established **dump-first**: for any Spoke-equivalent screen, consult the static dump (`docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md` light table + `~/spoke-dump/jadx-out` heavy decompiled code) BEFORE live runtime inspection — the dump is frozen fact (the *what*), runtime only confirms behavior the table's `Precisa-runtime` column flags (the *how*). It exists to kill the stale-inference rework that shipped the wrong widget four times (ADR-0041/0042/0043/0044).

But dump-first lived **only as prose** in three places (`CLAUDE.md`, `M2-SLICE-CHECKLIST.md`, `spoke-parity-checker.md`). Prose is ignorable, and it was ignored even by sessions that knew the rule:

- **MS-A5.7 (ADR-0046):** the session reached for Maestro runtime to discover the active-route config summary before establishing that the light table didn't cover it. It worked out, but the order was runtime-leaning.
- **MS-A5.8 (ADR-0047):** the session was about to inspect Spoke's route-creation flow live (which would create test routes on Eduardo's licensed account) to answer "is Detalhes FTUE-gated?" — until Eduardo intervened: *"temos o dump completo no nosso repo, isso não ajuda em nada?"* A `grep firstRoute|isFirst|hasSeenSetup ~/spoke-dump/jadx-out` answered it in seconds (no gate exists), no runtime, no account pollution.

The MS-A5.8 episode is the crisp motivation: **the dump can replace runtime entirely for behavioral/gating questions, and doing so avoids polluting the licensed Spoke install** — but only if a session actually reaches for it first. A second, related drift: `WebSearch`/Context7 were occasionally pointed at "how does Spoke do X" questions, when those belong to the dump; Context7/websearch are for **libraries** (new dependency, post-cutoff API), per the Context7-Mandatory rule.

Eduardo's directive: make dump-first (and "websearch/Context7 only when needed") a **formal gate** so every session/IA follows it, not just the ones that remember.

## Decision

Make dump-first a **signal-only** gate (warns, never blocks — matching the existing `warn-adr-drift`/`check-dto-mirror` philosophy; a hard PreToolUse block was rejected for false-positive friction on no-baseline Áreas and legitimately-new libraries). Four mechanisms:

**1. New Stop hook `warn-dump-first.sh` (signal-only).** At end of turn it inspects the transcript: if the session invoked **live Spoke runtime inspection** (`mcp__maestro__*` tools, or `adb shell`/`uiautomator`/`screencap` via Bash) OR a `WebSearch`, but did **not** consult the static dump first this session (no `Read` of `MASTER-TABLE.md` and no `grep` of `~/spoke-dump`/`jadx-out`), it prints a warning to stderr and exits non-zero. Silent (exit 0) otherwise. Wired into `.claude/settings.json` Stop hooks alongside `warn-adr-drift.sh`.

**2. SessionStart re-injection.** `reinject-roadmap.sh` (matcher `compact`) now also emits the dump-first + websearch-only-when-needed rule, so a session resumed after compaction stays aware of it (not just at cold start via CLAUDE.md).

**3. CLAUDE.md scope clause.** The Context7-Mandatory section gains an explicit scope note: Context7/`WebSearch` answer **library/framework** questions; they are **NOT** the source for **Spoke behavior** (that is dump-first → runtime confirm). The In-Loop Auto-Validation section lists `warn-dump-first.sh`. The header date bumps.

**4. M2-SLICE-CHECKLIST preflight items.** Two new checkboxes: (a) a Spoke behavior/gate question → grep `~/spoke-dump/jadx-out` before runtime; (b) websearch/Context7 only for libraries, with the `warn-dump-first.sh` signal noted.

**Exceptions (the hook and prose both name them):** Áreas without a Spoke baseline — **Á1 (auth leftovers)** and **Á11 (notifications)** — and **genuinely-new libraries** legitimately skip the dump. The hook's grep-based detection treats a heavy-dump grep as satisfying dump-first, so behavioral code-greps (the ADR-0047 pattern) don't false-positive.

## Consequences

- **Positive (gate, not just prose):** every session gets an in-loop nudge if it runs runtime/websearch without the dump, and every resumed session re-learns the rule. The discipline that depended on memory now has a mechanical backstop.
- **Positive (account hygiene):** steering behavioral/gating questions to the decompiled code (not live route-creation) avoids creating test state on the licensed Spoke install — a concrete operational win surfaced by ADR-0047.
- **Positive (clear lanes):** websearch/Context7 = libraries; dump = Spoke behavior; runtime = dynamic confirmation. Three sources, three jobs — no more pointing websearch at Spoke questions.
- **Negative (false positives possible):** the hook is heuristic (transcript grep). A session that legitimately skips the dump (Á1/Á11, new lib) will see the warning. Mitigated by: signal-only (never blocks), the warning text naming the exceptions, and the heavy-dump-grep escape hatch. If false positives prove noisy, tighten the detection (e.g. only warn when an inventory/Spoke file was also touched) in a follow-up.
- **Neutral (no new dependency):** pure bash + jq, matching the existing hook stack. No `package.json`/`pubspec` change, so no stack-ADR drift.

## Alternatives considered

1. **Hard PreToolUse block** (refuse Maestro/adb/websearch until the dump was read). Rejected — false positives would block legitimate work on no-baseline Áreas and new libraries, and "did this session consult the dump" is a fragile heuristic to gate execution on. High friction for marginal gain over a signal.
2. **Prose-only reinforcement** (strengthen CLAUDE.md/checklist, no hook). Rejected as insufficient — that is essentially today's state, and it was ignorable (the MS7/MS8 episodes happened *with* the prose in place). A mechanical signal is the missing piece.
3. **Put the signal in the spoke-parity-checker subagent only.** Rejected — the subagent is dispatched intentionally; the drift happens in the main loop before/around dispatch. A Stop hook covers the whole turn regardless of whether the subagent ran.

## References

- The method this enforces: [ADR-0045](./0045-spoke-static-dump-baseline.md) (static dump baseline)
- The motivating MS: [ADR-0047](./0047-route-defaults-persistence-no-ftue-gate.md) (dump grep answered the FTUE-gate question; no runtime)
- Hook: `.claude/hooks/warn-dump-first.sh` (+ `.claude/settings.json` Stop wiring)
- SessionStart injection: `.claude/hooks/reinject-roadmap.sh`
- Prose: `CLAUDE.md` (Context7-Mandatory scope clause + In-Loop Auto-Validation list + header), `docs/M2-SLICE-CHECKLIST.md` (preflight items)
- Sibling signal-only hooks: `warn-adr-drift.sh`, `check-dto-mirror.sh`, `analyze-changed-dart.sh` (ADR-0018)
- Memory: `lesson_master_table_covers_setup_not_active_shell` (the light-table/heavy-dump/runtime boundary this gate operationalizes)
