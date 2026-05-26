# ADR-0034: VoiceCapturePage uses a single "Adicionar parada" CTA (deviation from prototype)

- **Status:** Accepted
- **Date:** 2026-05-25
- **Deciders:** Eduardo (cliente Ueslei representative + product owner)
- **Related ADRs:** ADR-0010 (clone positioning), ADR-0021 (slice-2 fidelity remediation parent), ADR-0033 (PrimaryButton neon-dot removal — sibling visual deviation pattern)

## Context

The canonical UI source `prototipo/screens-a.jsx:396-408` defines `ScreenVoice` with a **two-button footer**: a `GhostButton "Parar"` (with `I.Square` icon) on the left and a plain transparent button `"Tentar novamente"` (with `I.RefreshCw` icon) on the right. The "Adicionar parada" CTA was implied to live elsewhere (the prototype is incomplete on this screen — there's no explicit confirm flow, since the prototype is a UI sketch, not a working speech recognizer).

During MS-15a-followup manual smoke on Samsung M54 (2026-05-25, session 26 Addendum 2), the initial implementation faithfully mirrored the prototype: `RpGhostButton "Parar"` + `TextButton.icon "Tentar novamente"` while empty, swapping to `RpGhostButton "Tentar novamente"` + `RpButton "Adicionar"` once a transcript existed. Eduardo found this cluttered — particularly since:

1. The mic tap itself already starts/stops listening (the gradient flips red→purple as a visual affordance).
2. "Tentar novamente" duplicates what a long-press or a second mic tap could do.
3. Two equal-weight footer buttons compete for attention with the gradient mic above.

He requested removal of both auxiliary buttons in favor of a single full-width `RpButton "Adicionar parada"` (enabled only when a transcript exists, otherwise `onPressed: null`).

## Decision

**Drop both "Parar" and "Tentar novamente" buttons from `VoiceCapturePage`.** The footer is a single `RpButton "Adicionar parada"` (`LucideIcons.check` icon, purple gradient when transcript present, disabled grey otherwise). Start/stop listening is consolidated into the mic tap itself — tapping the now-red square icon during listening calls `_toggleListen` and stops the engine; tapping again restarts.

## Options Considered

| # | Option | Verdict |
|---|---|---|
| 1 | Keep dual footer, accept M54 visual clutter | Rejected — cliente Ueslei feedback is canonical for this fork (per ADR-0010). |
| 2 | Drop "Parar" only, keep "Tentar novamente" as ghost | Rejected — same competing-attention problem; "Tentar" duplicates `_retry()` which is now reachable by just tapping the mic to restart. |
| 3 | **Drop both, single "Adicionar parada" CTA, mic-tap handles start/stop** | **Accepted.** Cleanest hierarchy: gradient mic is the sole interaction affordance, footer CTA is the commitment action. |
| 4 | Replace footer with no buttons at all (auto-confirm on engine `done`) | Rejected — confirmation must be explicit per the existing `_confirm` contract (creates a `Stop` via `stopsControllerProvider`). |

## Implementation summary

- **Removed:** `_retry()` method, `RpGhostButton "Parar"` import + usage, `RpGhostButton "Tentar novamente"` usage, the conditional 2-button row.
- **Kept:** `_toggleListen` (now reachable by tapping the gradient mic itself — already worked, just made it the only path), `_confirm` (CTA target).
- **New footer:** single `RpButton(label: 'Adicionar parada', icon: LucideIcons.check, onPressed: hasTranscript ? _confirm : null)`.
- The `_userWantsToListen` flag (added in the same commit set for the continuous-recognition auto-restart pattern) gives `_toggleListen` enough context to know whether to stop or start.

## Consequences

- **Prototype divergence #2** (after ADR-0033's neon dot). This time the prototype is NOT updated to match — Eduardo confirmed the prototype's two-button footer was always a sketch and the production app is the authoritative spec from here on. We accept the textual divergence in `prototipo/screens-a.jsx` because that file is also a sketch (not a binding contract).
- **Accessibility unchanged**: the single CTA gets explicit `Key('voice-confirm-button')` (preserved from the previous implementation, ensures existing tests still locate the confirm action). The mic itself has `Key('voice-mic-button')`.
- **TDD coverage**: the existing 2 widget tests still pass (`renders mic CTA and prompt copy`, `surfaces snackbar when microphone permission denied`). The new continuous-recognition auto-restart pattern is untested at widget level — it requires hooking into the SpeechToText status callback, which the existing test fakes don't expose. Manual smoke on M54 validated the behavior.
- **Future test debt**: should add an integration test that exercises the auto-restart path (start → speak → silence 4s → engine emits `done` → page re-listens → speak more → confirm) once the SpeechToText fake gains status-stream support. Tracked in TODO.md under "Discovered while working".

## Rollback

If we ever want the dual-button footer back:

1. Restore the conditional 2-button block from git history (commit predating this ADR).
2. Restore `_retry()` method and the `RpGhostButton` import.
3. Remove this ADR or mark it **Superseded**.

Total revert cost: ~5 min.

## Verification

- `flutter analyze --no-pub`: clean post-edit.
- `flutter test test/features/stops/presentation/voice_capture_page_test.dart`: 2/2 green.
- Full mobile suite: 173/173 green.
- Manual smoke on Samsung M54 (RQCW401G33T) via `flutter run` debug hot-reload: single CTA renders correctly; disabled state when transcript empty; enables (gradient purple) once words appear; tapping confirms and routes back to Home with the new Stop visible in the list.

## References

- `apps/mobile/lib/features/stops/presentation/voice_capture_page.dart` — current implementation.
- `prototipo/screens-a.jsx:366-411` — `ScreenVoice` (the divergent source — sketch, not binding).
- ADR-0033 — sibling deviation pattern (neon dot dropped).
- ADR-0010 — clone positioning ("we replicate flows, not visual identity; cliente preference governs visual choices").
- Session log 2026-05-25-26 Addendum 2 — the smoke that drove the decision.
