# ADR-0033: Drop the neon-green dot from `PrimaryButton` (deviation from prototype)

- **Status:** Accepted
- **Date:** 2026-05-25
- **Deciders:** Eduardo (cliente Ueslei representative + product owner)
- **Related ADRs:** ADR-0010 (clone positioning), ADR-0021 (slice-2 fidelity remediation parent), ADR-0032 (Lucide adoption)

## Context

The canonical UI source `prototipo/ui.jsx` defined `PrimaryButton` with an 8x8 neon-green dot (`RP.neon` = `#C6FF3D`) absolutely positioned at `right: 14, top: 50%` with a `0 0 8px rgba(198,255,61,0.9)` glow whenever `neon={true}`. The implementation mirrored this 1:1 in `apps/mobile/lib/core/widgets/rp_button.dart` (`_NeonDot` private widget rendered inside a `Stack` overlay).

During MS-15a-followup manual smoke on Samsung M54 (2026-05-25), Eduardo flagged the dot on the "Otimizar rota" CTA (HomeListPage) as visually distracting and requested its removal. The CLAUDE.md "UI Source of Truth" rule normally forbids divergence from `prototipo/`, so this decision was escalated and locked explicitly rather than swept silently.

## Decision

**Drop the neon dot from `PrimaryButton` entirely.** The `neon: bool` flag still toggles the gradient background (`primary → primaryDark` 135°), which is the dominant visual signal. The dot is removed from both the Flutter widget and the React prototype in the same commit set to keep the two sources aligned (per CLAUDE.md §"UI Source of Truth").

## Options Considered

| # | Option | Verdict |
|---|---|---|
| 1 | Keep dot, accept divergence between client visual preference and prototype | Rejected — silent divergence violates CLAUDE.md; cliente Ueslei is the eventual end user and his preference is canonical for this fork. |
| 2 | Remove dot from RpButton only (Flutter), keep in prototype | Rejected — creates persistent visual drift; future fidelity audits would re-flag the dot as a gap. |
| 3 | **Remove dot from both `RpButton` and `prototipo/ui.jsx` `PrimaryButton`** | **Accepted.** Aligns the two sources; documents the deviation here for traceability. |
| 4 | Remove `neon` boolean entirely (always render gradient when not disabled) | Rejected — `neon` still affects gradient vs solid background; other call sites may rely on solid primary. Keeps API surface intact. |

## Implementation summary

- `apps/mobile/lib/core/widgets/rp_button.dart`: deleted the `_NeonDot` private widget and the `Stack` overlay; the button body is now a plain `Row` (gradient + shadow + label intact).
- `prototipo/ui.jsx`: deleted the `{neon && (<span .../>)}` block inside `PrimaryButton`.
- No tests referenced `_NeonDot` directly — `rp_button` widget tests check the gradient/label/icon, not the dot.

## Consequences

- **Spoke parity:** This is the first formal acknowledged deviation from `prototipo/`. The fork is still a *functional* clone of Spoke (per ADR-0010); the visual identity remains 100% original, and the cliente's call governs visual decisions of this scope.
- **Future fidelity audits:** `prototype-fidelity-checker` subagent should NOT flag the missing dot anymore — the prototype no longer has it. Confirmed by re-reading `prototipo/ui.jsx` line 68-90 (matches `PrimaryButton` in `rp_button.dart`).
- **No API surface change:** `RpButton(neon: true)` still works — it toggles the gradient, just without the dot accent.

## Rollback

If we ever want the dot back:

1. Restore the `_NeonDot` widget in `rp_button.dart` from git history (commit predating this ADR).
2. Restore the `{neon && <span ...>}` block in `prototipo/ui.jsx`.
3. Remove this ADR or mark it **Superseded**.

Total revert cost: ~5 min.

## Verification

- `flutter analyze --no-pub`: clean post-edit.
- `flutter test`: 173/173 green (no test depended on `_NeonDot`).
- Manual smoke on Samsung M54 (RQCW401G33T) via `flutter run` hot-reload: dot removed, gradient intact, no visual regression on other `RpButton` usages (HomeListPage "Otimizar rota", HomeEmptyPage CTA, ReorderPage CTA).

## References

- `prototipo/ui.jsx:68-90` (post-edit) — `PrimaryButton` without dot.
- `apps/mobile/lib/core/widgets/rp_button.dart` — Flutter mirror.
- MS-15a-followup session log addendum (this session) — manual smoke that surfaced the request.
- CLAUDE.md §"UI Source of Truth" — clause this ADR formally invokes to record the deviation.
