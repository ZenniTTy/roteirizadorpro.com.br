# Workflow templates for Slice 2 Area 5+ microsprints

These are reusable Workflow scripts that encode the harness improvements from `~/.claude/projects/.../memory/feedback_spec_baseline_and_workflow_halt.md`. Each MS dispatch (MS4 onward) calls one of these templates instead of inlining the orchestration in the controller — the rules are now executable code, not advisory text.

## Available templates

| Template | Purpose |
|---|---|
| `area5-microsprint.js` | Full 5-phase MS dispatch: preflight → spoke-baseline → library-research → halt-gate → implement → review. Reusable for MS4, MS5, MS6, MS8 (any MS that builds a Spoke-equivalent widget). |
| `area5-cleanup.js` | (Not yet needed — keep this file when an MS needs zero-debt cleanup after main implementation, like MS3 fix-6.) |

## Invocation pattern

The controller (me) calls these via `Workflow({scriptPath: '.claude/workflows/area5-microsprint.js', args: {...}})`. The `args` object carries the MS-specific configuration — see each template's `meta.argsSchema` for the expected shape.

## Why these exist (one-line rationale)

Inline workflow scripts grew error-prone because the same orchestration patterns (halt-on-stop-signal, implementer-can-contradict-spec, spec-baseline-preflight) were re-written from scratch each dispatch. When the controller forgot to add them, the result was the MS4 wheel_picker failure (workflow `wrqvzoso8`): Phase 2 said "STOP" but Phase 3 fired because the script had no `if shouldHalt then return` branch. Templates fix this by making the gate **un-skippable**.
