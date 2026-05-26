# ADR-0032: Adopt `lucide_icons_flutter` as the canonical icon set

- **Status:** Accepted
- **Date:** 2026-05-25
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0006 (Flutter + Riverpod stack lock), ADR-0014 (APK distribution), ADR-0021 (slice-2 fidelity remediation parent)

## Context

The canonical UI source `prototipo/icons.jsx` defines all interface icons using **Lucide** (outlined, 24px, stroke 1.5). The implementation has been using Material Design icons (`Icons.alt_route`, `Icons.mic`, `Icons.camera_alt`, `Icons.keyboard`, etc.) because Lucide was not installed and Material was the path of least resistance.

`TODO.md` line 139 has tracked this gap as an open policy decision since slice 2 began. MS-15a-followup (session 26 manual smoke on Samsung M54) surfaced 6 fidelity gaps where icon mismatch was a contributing factor (AddStop method buttons, BottomNav, FAB, StopCard handles, VoiceCapturePage). Eduardo confirmed cliente Ueslei's expectation is **Spoke-parity** (CLAUDE.md "What This Project Is") — so the prototype's icon family must land in the implementation. This decision was deferred until a concrete microsprint needed it. MS-15a-followup is that microsprint.

## Decision

**Adopt `lucide_icons_flutter` (^3.1.14) as the canonical icon set for the Roteirizador Pro mobile app.** Material icons are still allowed where a specific icon has no Lucide equivalent OR where Material's semantic mapping is materially better, but **default to Lucide for all new code and re-skin existing screens opportunistically when their tests are touched** (Karpathy §3 surgical principle — don't do a one-shot sweep that touches every file).

## Options Considered

| # | Option | Verdict |
|---|---|---|
| 1 | Keep Material as canonical, accept Lucide mismatch as permanent | Rejected — violates CLAUDE.md "What This Project Is" (Spoke-parity is North Star); cliente saw prototype with Lucide. |
| 2 | `lucide_icons` (official `lucide.dev` publisher) | Rejected — pub score 45/160 (significantly below threshold), suggesting build-config issues. Only 122 likes vs 171 for the alternative. |
| 3 | **`lucide_icons_flutter` (vqh2602)** | **Accepted.** Pub score 160/160 (perfect), 171 likes, 97.8k downloads/30d (10× higher than alternatives), MIT license, active maintainer, API is a drop-in replacement for Material `Icons.x` (`LucideIcons.x`). |
| 4 | `flutter_lucide` (voltvave) | Rejected — score 160/160 but only 85 likes + 9.2k downloads (~10% of option 3). Smaller community = higher abandonment risk. |
| 5 | `amicons` (multi-icon-family hub including Lucide) | Rejected — bundles 10K+ icons across 5 families; bloats APK with sets we don't need; introduces decision overhead per icon. |

## Implementation summary

- **New dependency:** `apps/mobile/pubspec.yaml` gains `lucide_icons_flutter: ^3.1.14`.
- **Import pattern:** `import 'package:lucide_icons_flutter/lucide_icons.dart';` then `Icon(LucideIcons.iconName, size: ..., color: ...)`.
- **MS-15a-followup re-skin scope:** AddStopSheet `_MethodButton` (gap #6), HomeBottomNav (gap #4), HomeListPage FAB (gap #3 — `LucideIcons.plus`), StopCard grip handle (gap #5 — `LucideIcons.gripVertical`), VoiceCapturePage (gap #1 — `LucideIcons.mic`, `LucideIcons.square`, `LucideIcons.refreshCw`).
- **Material icons NOT swept this microsprint:** every other screen keeps Material until its own remediation microsprint touches it. Karpathy §3 — don't touch what doesn't need touching.

## Consequences

- **APK size:** `lucide_icons_flutter` ships as a font (`.ttf`) plus const `IconData` codepoints. Tree-shaking keeps only the icons actually used. Expected APK growth ~80-150 KB.
- **Visual fidelity:** Prototype's `prototipo/icons.jsx` maps 1:1 to `LucideIcons.x` (the package is a direct Flutter port of the same Lucide SVG source). No icon-shape divergence anymore for re-skinned screens.
- **Dual icon families during transition:** until every screen is re-skinned, the app will have both Material and Lucide icons visible. Acceptable per Karpathy §3.
- **CLAUDE.md stack table:** doesn't list icon family explicitly today; this ADR is the lock. CLAUDE.md update can happen here OR in a follow-up `docs(claude)` commit.

## Rollback

If `lucide_icons_flutter` proves problematic (unmaintained, build-breaking, license change):

1. Switch to `flutter_lucide` (the option-4 sibling — same Lucide source, different publisher).
2. Sweep `import 'package:lucide_icons_flutter/lucide_icons.dart'` → `import 'package:flutter_lucide/flutter_lucide.dart'` (one `grep -rn + sed` command).
3. The API surface (`LucideIcons.x`) may differ slightly — check the alternative package's exports table.

Total revert cost: 30 min of grep+sed + a fresh `flutter pub get`.

## Verification

- Inline at adoption: `flutter pub get` resolves without conflict; `flutter analyze --no-pub` clean post-import; one `Icon(LucideIcons.mic)` test render produces visible glyph on Samsung M54 via hot restart.
- Per re-skinned screen: prototype-fidelity-checker subagent should stop flagging "icon family" Minor divergence on that screen (was m-3/m-4/m-5 in MS-15a fidelity report).
- Per ADR's "Material icons NOT swept this microsprint" rule: any other screen that wasn't touched by MS-15a-followup keeps its Material icons; that's expected, not a regression.

## References

- pub.dev: `https://pub.dev/packages/lucide_icons_flutter` (3.1.14+2 at decision time, score 160/160, 171 likes, 97.8k downloads/30d).
- Lucide source: `https://lucide.dev` — the SVG icon set both Lucide packages port.
- Context7 docs validated 2026-05-25: API stable, drop-in for Material `Icons.x`.
- `prototipo/icons.jsx` — canonical icon mapping (Lucide outlined, 24px, stroke 1.5).
- MS-15a-followup session log addendum (this session) — the smoke that surfaced the need.
