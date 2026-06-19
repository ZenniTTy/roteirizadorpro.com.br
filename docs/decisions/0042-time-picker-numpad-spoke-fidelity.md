# ADR-0042: Time picker = numeric keypad (supersedes ADR-0041 wheel_picker)

- **Status:** Accepted (supersedes [ADR-0041](./0041-wheel-picker-time-drum.md))
- **Date:** 2026-06-03
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (Spoke white-label hierarchy), ADR-0036 (parity gates), ADR-0037 (Maestro MCP), ADR-0041 (superseded — wheel_picker)

## Context

[ADR-0041](./0041-wheel-picker-time-drum.md) adopted `wheel_picker ^0.3.0` for the "Início" and "Término" time pickers in MS4. The decision relied on `/tmp/spoke-a5-iniciar-time.png` as the Spoke baseline. **That baseline file was 0 bytes** (truncated during the 2026-06-01 /tmp purge that wiped all XML dumps; the PNG was also empty but not verified at the time the spec was drafted). The drum-picker assumption was therefore **an inference, not a measurement** — Material 3's most common time picker shape filled in for an unverified Spoke widget.

The MS4 workflow (2026-06-03, `wrqvzoso8`) ran a fresh live Spoke inspection on the M54 and produced 12 new screenshots (`/tmp/spoke-a5-inspection/step1..step12.png`). The inspection shows Spoke's time picker is **NOT a drum/wheel**. It is a 4×3 numeric keypad inside a Material `BottomSheetDialog` (`bsp_time_picker`), with `:00` and `:30` minute-shortcut keys integrated into the keypad grid, a FAB confirm, header live-text input, and tap-outside-to-cancel semantics. No scroll wheel exists anywhere in the flow.

This is a material parity failure that traces to the spec-drafting protocol (inferring from inventory text instead of verifying with a live screenshot of the specific sub-widget). The corrective rule is now memorialized in `~/.claude/projects/.../memory/feedback_escalate_recurring_and_gate_check.md` and the spec-drafting protocol below.

## Decision

**Supersede ADR-0041 entirely.** The "Início" and "Término" time pickers in MS4 will implement a numeric keypad widget matching Spoke's `bsp_time_picker`:

- Bottom sheet via `showModalBottomSheet` (Material 3, `isScrollControlled: true`, `useSafeArea: true`, `barrierColor: Colors.black54`, `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)))`).
- Header (`~77dp`): live-updated `Text` showing either the placeholder title (e.g. `"Definir horário de início"` / `"Definir horário de término"`) or the accumulating digit buffer.
- Body (`~388dp`): `GridView.count(crossAxisCount: 3)` with 12 keys — rows 1-9 + row [`:00`, 0, `:30`]. Digit keys append to a local `StatefulWidget` buffer (`String _buffer = ''`). `:00` and `:30` are minute-shortcut keys (enabled only after at least one hour digit is typed; they auto-complete the minute portion).
- Backspace (`ImageButton`-equivalent): erases the last buffer character; disabled when buffer is empty.
- Confirm (FAB, `LucideIcons.check`): disabled (grey) when buffer is incomplete; enabled (`AppColors.primary` fill) when buffer represents a valid `HH:MM` 24-hour clock; on tap `Navigator.pop<TimeOfDay>(picked)`.
- Cancel: tap-outside the sheet pops with `null`. No leading X, no trailing button in the header.
- Buffer state: ALWAYS resets to empty when the sheet opens — never pre-populated with `config.timeStart` or `config.timeEnd` (Spoke does not pre-fill, see step9-reinspect-inicio.png).
- No cross-field validation in the picker itself (end-before-start is checked at `isRouteConfigValidProvider` on the page-level "Concluído" button, not inside the picker). The picker accepts any valid 24-hour clock value independently.

**Remove the `wheel_picker` dependency** from `apps/mobile/pubspec.yaml`. ADR-0041 is marked Superseded; the file is preserved for historical reference but its decision no longer applies.

## Consequences

- **Positive (parity):** Spoke 1:1 at the most-visible time-input surface of Area 5. Rider muscle memory preserved.
- **Positive (simplicity):** ~80 LOC `StatefulWidget` (header `Text` + 4×3 `GridView` + buffer `String` + 3 small helpers). No external dependency, no transitive deps to audit, no version-lock concerns.
- **Positive (tests):** widget tests trivial — tap each digit, assert buffer state, assert FAB enabled/disabled, assert pop value. ~10 widget tests sufficient.
- **Positive (process):** documents the inference-vs-measurement failure mode so future ADRs flag the same risk pattern earlier.
- **Negative (sunk cost):** `c4dc266` + `6c00852` (wheel_picker implementation, 698 LOC, 18 widget tests) are reverted before push. Net learning: ~2h of implementer time + 41 min of workflow; ~1h was the inspection itself which produced reusable baseline screenshots (kept).

## Alternatives considered

1. **Keep wheel_picker + amend ADR-0041 to accept the divergence as intentional.** Rejected — directly contradicts ADR-0035 (Spoke is canonical for behavior). The point of the spoke-parity-checker subagent and the live-inspection discipline (ADR-0036) is that we follow Spoke when Spoke disagrees with assumption.
2. **Keep wheel_picker for MVP, defer numpad to a post-Slice-2 polish ADR.** Rejected — explicit "defer to later MS" is what `feedback_spoke_parity_zero_debt_per_ms` was created to ban after the MS2 Iniciar-vs-Início incident. Same anti-pattern.
3. **Numpad now, wheel as opt-in setting later.** Rejected — Spoke does not expose this choice; adding it is a feature creep that violates Karpathy 2 (Simplicity First).

## Spec-drafting protocol amendment (new — applies from this ADR onward)

Every Q-table decision that names a widget shape, package, or interaction model **must cite either**:
- (a) **A non-zero-byte PNG screenshot file** in `/tmp/spoke-*/` of the specific Spoke widget the decision concerns; OR
- (b) **An explicit `[INFERRED — VERIFY BEFORE LOCK]`** marker in the rationale column.

When marker (b) is used, the spec is non-final until a live Spoke inspection of the specific widget produces a PNG that either confirms the inference (mark removed, decision locked) or contradicts it (decision revised, new ADR if needed). Lockable specs cannot ship with `[INFERRED]` markers unresolved.

This rule lives operationally in `~/.claude/projects/.../memory/feedback_spec_drafting_requires_live_widget_baseline.md`.

## References

- Spec: `docs/superpowers/specs/2026-06-02-area5-route-details.md` (Q3 row — being amended in the same commit as this ADR)
- Superseded: [ADR-0041](./0041-wheel-picker-time-drum.md)
- Spoke baseline (numpad): `/tmp/spoke-a5-inspection/step2-time-iniciar.png`, `step3-type1.png`, `step4-typed-1030.png`, `step5-after-confirm-iniciar.png`, `step6-time-termino.png`, `step9-reinspect-inicio.png` — all captured 2026-06-03 via Maestro MCP + adb fallback
- Live inspection workflow: `wrqvzoso8` (2026-06-03, 4-phase MS4 dispatch)
- Memory: `feedback_spoke_parity_zero_debt_per_ms`, `feedback_escalate_recurring_and_gate_check`
- pub.dev (no longer used): <https://pub.dev/packages/wheel_picker>
