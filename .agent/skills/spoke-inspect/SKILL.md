---
name: spoke-inspect
description: Use when entering brainstorming for any slice-2 or slice-3 microsprint with a Spoke equivalent (BEFORE writing the spec), and again at D4 closing (BEFORE opening the slice PR). Inspects the reference Spoke install (com.underwood.route_optimiser) on Eduardo's connected Samsung M54 to produce a paste-verbatim view hierarchy + categorized parity punch-list (must-fix / should-fix / nit). Read-only — never edits code. Mirrors the Claude Code spoke-parity-checker subagent.
---

# spoke-inspect

Inspect Spoke (the reference app for behavior parity per ADR-0035 / ADR-0036 / ADR-0037) and produce a structural punch-list against the matching Roteirizador Pro flow.

## When to use this skill

Two dispatch points per microsprint — same workflow, different purposes:

1. **Upfront (brainstorming)** — BEFORE the spec is written. Builds a structural baseline that informs the spec and replaces UI/UX questions Spoke already answers. RotPro side may be empty/stub at this point — that's expected; the report focuses on Spoke's structural facts.

2. **D4 closing (pre-PR)** — when the microsprint finishes its green pass. Closing functional-parity verification.

**Do NOT use this skill for:**
- Slice 4 (Stripe Pix paywall) — original RotPro, no Spoke equivalent.
- Slice 5 (sentido casa) — original RotPro.
- Slice 6 (LGPD) — legal-only.
- Slice 7 (admin panel) — original RotPro.

## Pre-flight checklist (refuse to proceed if any fail)

1. **Device connected:** `adb devices` must show `RQCW401G33T` (Eduardo's M54). If not, ask the operator to plug the device and enable USB debugging.

2. **Spoke installed and logged in:** ask the operator to confirm Spoke is on the device and that they are logged in (the reference UX depends on authenticated state).

3. **MCP server available:** Maestro MCP is preferred (per ADR-0037). Verify `mcp__maestro__list_devices` returns the M54. If unavailable, fall back to bash + `adb shell uiautomator dump` (same Android Accessibility surface, slower workflow).

4. **Working directory for dumps:** `/tmp/spoke-inspection/` (gitignored by pattern `**/spoke-inspection/`). Never write inspection artifacts inside the repo.

## Inspection workflow

### Step 1 — Identify the target flow

Ask the operator (or read from context) which Spoke flow you are inspecting. Common targets per slice-2 inventory:
- Route list (home)
- Stop detail
- Add stop / address search
- Optimization result
- Route share
- Settings

### Step 2 — Launch and navigate Spoke

Preferred (Maestro MCP):
```
mcp__maestro__launch_app(appId: "com.underwood.route_optimiser", device_id: <M54>)
mcp__maestro__inspect_view_hierarchy(device_id: <M54>)
mcp__maestro__tap_on(...) / mcp__maestro__back(...) as needed
mcp__maestro__take_screenshot(device_id: <M54>) at each significant state
```

Fallback (bash):
```bash
adb shell am start -n com.underwood.route_optimiser/<MainActivity>
adb shell uiautomator dump /sdcard/spoke.xml && adb pull /sdcard/spoke.xml /tmp/spoke-inspection/
adb shell screencap /sdcard/spoke.png && adb pull /sdcard/spoke.png /tmp/spoke-inspection/
```

### Step 3 — Inspect the RotPro equivalent (if it exists)

For D4 dispatches, repeat the inspection on the RotPro build. For upfront dispatches, the RotPro flow may not exist yet — that's expected; note it in the report as "RotPro: not yet implemented."

### Step 4 — Cross-reference the inventory

Open `docs/inventory/2026-05-26-spoke-vs-rotpro.md`, find the matching slice section, and use it as the structural canonical mapping. Update the inventory ONLY if the operator explicitly asks (this skill is read-only on code; inventory edits are a separate task).

## Report format

Produce a Markdown report with the following sections. Be paste-verbatim wherever possible — no paraphrasing into existence.

```markdown
# Spoke inspect: <flow name>

**Dispatch point:** upfront / D4
**Inspection path:** Maestro MCP / bash + uiautomator
**Spoke version inspected:** <version from Play Store metadata if visible, else "unknown">
**RotPro state:** not implemented / implemented (commit <sha>)

## Spoke structural facts (paste-verbatim)

<View hierarchy excerpts from Maestro / uiautomator dump.
Quote element labels, roles, positions verbatim. Do not paraphrase.>

## RotPro structural facts (D4 only)

<Same format for the RotPro equivalent.>

## Parity punch-list

### Must-fix (blocks PR)
- <gap>

### Should-fix (file as follow-up if not addressed this sprint)
- <gap>

### Nit (defer to polish phase)
- <gap>

## Inventory delta

<If the inventory section is stale or missing facts the inspection revealed,
list what needs updating. Do not edit the inventory in this skill — surface it.>
```

## Strict boundaries

- **Read-only on code.** Do not edit any file under `apps/mobile/lib/`, `apps/backend/src/`, or `docs/`.
- **No decompilation.** Do not extract APK assets, do not run `apktool`, do not inspect `/data/data/com.underwood.route_optimiser/`. The legal posture per ADR-0010 is runtime UI state observation only via Android Accessibility.
- **No screenshots into the repo.** Screenshots and XML dumps go to `/tmp/spoke-inspection/` and stay there.
- **Inventory edits are not your job.** If you spot drift in `docs/inventory/2026-05-26-spoke-vs-rotpro.md`, surface it in the "Inventory delta" section — do not edit.

## ADR references

- ADR-0010 (legal posture: functional fork, no asset reuse)
- ADR-0035 (Spoke = behavior canonical; prototipo = visual only)
- ADR-0036 (parity gate: upfront + D4 dispatch)
- ADR-0037 (Maestro MCP preferred; bash + uiautomator fallback)
