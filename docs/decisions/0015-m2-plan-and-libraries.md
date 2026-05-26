# ADR-0015: M2 Plan and Library Choices

- **Status:** Accepted
- **Date:** 2026-05-13
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0002 (Flutter mobile), ADR-0007 (Efí Bank Pix — **superseded by ADR-0030**), ADR-0008 (GraphHopper routing), ADR-0014 (Android release signing). Subsequent slice-specific ADRs (0016, 0017, 0018, 0019, 0020, 0021) elaborate individual slices.

## Context

M2 is contracted at BRL 2,000 with the same client who funded M1, with the same operating constraint: keep infrastructure cost extremely low while preserving the security, scalability, and quality of M1's delivery. The original Workana proposal lists seven sub-deliverables (APK, Telas, Optimization, Pix, Sentido casa, LGPD, Admin) without ordering them. Slice 1 (APK) shipped 2026-05-13 as `v1.0.0`.

This ADR codifies:

1. The locked **execution order** of the remaining six slices.
2. The **single source of truth** that future sessions follow (`docs/08-ROADMAP-v2.md` post-ADR-0035; was `docs/08-ROADMAP.md` until 2026-05-26 — now archived to `docs/archive/`), supported by `M2-SLICE-CHECKLIST.md` and `M2-COST-MODEL.md`.
3. The **library choices** for slice 2 — the next slice — validated against Context7 on the day of this ADR.

The library validation matters because the LLM agent's training cutoff is January 2026 (per the current Claude Code agent), and the M2 work spans libraries that have moved since then. Without Context7 each library risks shipping with a stale version pin or a missing migration step.

## Options Considered

### Order of M2 slices

#### Option A — Distribution → UX → Logic → Monetization → Polish (this ADR)

`APK → Telas Core → VRP → Pix → Sentido casa → LGPD → Admin`. Order matches "destrava distribuição first; then build the user-visible experience; then the optimization that makes it useful; then monetization; then the smaller polish + compliance items."

- Pros: Slice 1 (APK) unlocks real-device testing of every subsequent slice. Telas (slice 2) make the optimization (slice 3) testable end-to-end. Payment (slice 4) lands only after the product is worth paying for. LGPD and admin are kept toward the end because they're cheaper when the rest is stable.
- Cons: Pix lands later than monetization-first frameworks would prefer. Mitigated by the fact that beta users can still use the product for free until slice 4 lands.

#### Option B — Pix first

`Pix → APK → Telas → VRP → rest`.

- Pros: Lets us validate monetization economics before the UI work.
- Cons: Pix alone is useless without the product. The Efí integration also has a hard external dependency (the two partners' Efí accounts must be active and the `.p12` mTLS certs delivered before code starts); discovering that mid-flight on the first slice would block everything. **Rejected.**

#### Option C — Big-bang merge at the end

Build all six slices on parallel feature branches, merge in one PR.

- Pros: Theoretically less context-switching.
- Cons: Slice 1 already proved we miss things between merges (the INTERNET-permission bug, the session-end commit lost between PR #3 and PR #4). A six-slice big-bang would multiply that risk. **Rejected.**

### Map / tile provider for slice 2

#### Option α — `flutter_map` + public OSM tiles (this ADR)

- Pros: Apache 2.0; vendor-free; mature (Context7 score 91/100); no SDK lock-in; OSM tile usage is **free for compliant low-volume usage**. Cost in `M2-COST-MODEL.md` is 0 BRL/month.
- Cons: Subject to OSMF's acceptable-use policy; if we hit heavy usage we self-host (documented in ADR-0016).

#### Option β — `google_maps_flutter`

- Pros: Best-in-class UX; well-known API.
- Cons: At our projected scale (100 paying users × 10 routes/day × 20 stops × N tile loads) the bill goes from free-tier to thousands of USD quickly. We can't afford it within the M2 cost ceiling. **Rejected.**

#### Option γ — `mapbox_maps_flutter`

- Pros: Cleaner API than Google's; generous free tier (200k loads/month).
- Cons: Vendor lock-in; the migration off it back to OSM later is non-trivial. Starting with OSM keeps the door open. **Deferred to the heavy-usage migration in ADR-0016.**

### Voice → text for slice 2

#### Option δ — `speech_to_text` 7.x (this ADR)

- Pros: On-device (Android `SpeechRecognizer`, iOS `Speech`); supports pt-BR; zero per-request cost; Context7 score 94/100; maintained.
- Cons: Recognition quality depends on the device; older Android devices may not have pt-BR locale installed.

#### Option ε — Google Cloud Speech-to-Text via REST

- Pros: Higher accuracy.
- Cons: Per-request cost outside the M2 ceiling. **Rejected.**

### OCR for slice 2

#### Option ζ — `google_mlkit_text_recognition` 0.x (this ADR)

- Pros: On-device; zero per-request cost; Context7 score 89/100; the only mature on-device OCR for Flutter Android.
- Cons: Adds ~5 MB to the APK due to bundled ML model. Acceptable.

#### Option η — Tesseract or open-source OCR via FFI

- Pros: Truly offline, no ML Kit dependency.
- Cons: Significantly heavier setup; lower accuracy on real-world AWB labels. **Rejected.**

### Route optimization (slice 3 preview)

#### Option θ — In-process TSP solver in Node TypeScript backed by GraphHopper for distance matrix (this ADR)

- Pros: Zero new dependencies; runs on existing infrastructure; deterministic; ~150 LOC for nearest-neighbor + 2-opt; sufficient quality for our 20-stop input cap. Slice 3 ADR-0019 details the implementation.
- Cons: Not Pareto-optimal for very large inputs; doesn't handle time windows. We don't need either in M2.

#### Option ι — Paid GraphHopper Directions Cloud

- Pros: Solver included; high quality.
- Cons: EUR 199/month minimum. Above the cost ceiling. **Rejected.**

#### Option κ — Google OR-Tools via Node bindings

- Pros: Industry-standard solver.
- Cons: `node-or-tools` is unmaintained as of 2025; introduces a C++ build dependency on the droplet. **Rejected.**

## Decision

1. **Slice order locked** as Option A: APK (✅ shipped) → Telas Core → VRP → Pix → Sentido casa → LGPD → Admin.

2. **The single source of truth for M2 is `docs/08-ROADMAP-v2.md`** (was `docs/08-ROADMAP.md` until 2026-05-26 ADR-0035 pivot — v1 archived to `docs/archive/`). All M2 docs cross-reference back to it. When any doc disagrees with the active roadmap, the roadmap wins and the contradiction is a bug to fix in the same PR.

3. **Slice 2 libraries** (validated via Context7 on 2026-05-13):

   | Purpose | Package | Version target | Cost | Context7 ID |
   |---|---|---|---|---|
   | Map widget | `flutter_map` | ^8.3.0 | 0 | `/fleaflet/flutter_map` |
   | Map coords | `latlong2` | ^0.9.1 | 0 | transitively required by `flutter_map` |
   | User location | `geolocator` | ^14.0.2 | 0 | latest 2025 |
   | Speech-to-text | `speech_to_text` | ^7.3.0 | 0 (on-device) | `/csdcorp/speech_to_text` |
   | OCR | `google_mlkit_text_recognition` | ^0.15.1 | 0 (on-device) | `/websites/pub_dev_google_mlkit_text_recognition` |
   | Native share sheet | `share_plus` | ^12.0.2 | 0 | well-established |
   | Stable IDs | `uuid` | ^4.5.3 | 0 | well-established |
   | Local persistence | `shared_preferences` | ^2.5.5 | 0 | well-established |
   | External app hand-off | `url_launcher` | ^6.3.2 | 0 | well-established |
   | Runtime permissions | `permission_handler` | ^12.0.1 | 0 | well-established |
   | Photo capture / gallery | `image_picker` | ^1.2.2 | 0 | well-established |
   | Brand icon set (WhatsApp) | `font_awesome_flutter` | ^10.12.0 | 0 | `fluttercommunity` (FA 7.2.0 free; 2000+ icons; WhatsApp brand glyph) |
   | QR-code generator | `qr_flutter` | ^4.1.0 | 0 | `/theyakka/qr.flutter` (null-safe; on-device; auto version detection) |

   **Update 2026-05-18 (slice 2 sub-2a):** versions resolved by `flutter pub add` and recorded in `apps/mobile/pubspec.lock`. Five new libs (`uuid`, `shared_preferences`, `url_launcher`, `permission_handler`, `image_picker`) joined the original six listed above; the full list is reflected in the table.

   **Update 2026-05-20 (slice 2 sub-2e / MS-12):** two new direct deps added for the named-channel ShareSheet rebuild (Reorder catalog row 18 / C-1):

   - `font_awesome_flutter: ^10.12.0` — `FaIcon(FontAwesomeIcons.whatsapp)` gives the canonical WhatsApp brand glyph (`prototipo/screens-b.jsx:406` shows the green-circle WhatsApp icon). Material Icons has no WhatsApp brand glyph; the alternative was bundling a custom SVG asset, which Context7 confirmed is heavier and harder to color-tint than `FaIcon`. Cost: 0 (font asset, no network).
   - `qr_flutter: ^4.1.0` — `QrImageView(data: 'https://roteirizadorpro.com.br/download', version: QrVersions.auto, size: 180)` per Context7 `/theyakka/qr.flutter`. Renders an on-device QR pointing at the APK download URL; the prototype's expanded QR card at `screens-b.jsx:438-447` mandates this. Alternative was a static PNG asset bundled in `assets/` — rejected because the URL may change before launch. Cost: 0 (pure-Dart canvas painter, no network).

   Both deps are on the cost ceiling (free, on-device, no per-request cost). Validated via Context7 + WebSearch May 2026 before adding.

4. **OSM tile policy** must be honored:

   - `userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro'` on every `TileLayer`.
   - `RichAttributionWidget` with "OpenStreetMap contributors" on every screen with a map.
   - The migration trigger to self-hosted tiles is documented in **ADR-0016** (filed in the same PR as this ADR).

5. **Andoid runtime permissions** added in slice 2: `ACCESS_FINE_LOCATION` (geolocator), `RECORD_AUDIO` (speech_to_text), `CAMERA` (ML Kit text recognition). Each added to `src/main/AndroidManifest.xml` per the slice 1 lesson (permission overlays in `src/{debug,profile}/` don't merge into release builds).

6. **Route optimization (slice 3)**: in-process Node TS solver. Full design in ADR-0019.

## Consequences

- **Positive:** clear order; clear cost ceiling; libraries are mature and free; no surprise infrastructure-cost surprises mid-slice; future agents have a single canonical entry point (`08-ROADMAP-v2.md` post-ADR-0035).
- **Negative:** running on the OSM public tile policy is a soft constraint; if we ever ship to ≥ 500 paying users on the current stack we will likely need to self-host tiles (planned in ADR-0016).
- **Neutral:** ADRs 0016-0021 will land one-per-slice as the slices ship, capturing the local design decisions.

## Implementation Notes

This ADR governs the **plan**. Each slice's local design lives in its own ADR, filed when the slice starts:

| Slice | ADR | Owner |
|---|---|---|
| 1 — APK | ADR-0014 (shipped) | filed 2026-05-13 |
| 2 — Telas Core (map + tiles) | ADR-0016 (this PR) | tile policy + migration trigger |
| 2 — Telas Core (navigation hand-off) | ADR-0017 (filed during slice 2) | deep-link to Google Maps / Waze vs in-app turn-by-turn |
| 3 — VRP (geocoding via Nominatim) | ADR-0018 (filed during slice 3) | Nominatim policy + migration trigger |
| 3 — VRP (solver) | ADR-0019 (filed during slice 3) | matrix-from-individual-routes + nearest-neighbor + 2-opt |
| 4 — Pix Split | covered by ADR-0007 (already accepted) | only files a new ADR if we deviate from ADR-0007 |
| 6 — LGPD | ADR-0020 (filed during slice 6) | export format, delete semantics |
| 7 — Admin | ADR-0021 (filed during slice 7) | role model, route protection |

The decision rule for whether a slice needs its own ADR: **any new dependency, any new external service, any pattern future agents would need to understand → ADR.** Pure feature work within an existing pattern → no ADR, just the slice's session log.

### Slice-2 schema shape promotion (note, 2026-05-19)

`OptimizeResponseSchema` was promoted from the M1 placeholder (`{ status: 'not_implemented', message: String }`) to the wire-final shape (`{ optimizedOrder: int[], totalDistanceM: number, totalDurationS: number }`) inside slice 2 (commits `c45f742` + `7437c1a`), even though the real solver is slice 3 work per item 6 above. The slice-2 handler returns the input order with `totalDistanceM=0` and `totalDurationS=0` as a 200 mock; slice 3 will swap the handler implementation only — the schema does not change. This is intentional: shipping the final response shape early lets the mobile DTO (`OptimizeResult` in `optimize_controller.dart`) and the consumer screens (`OptimizeRoutePage`, `RouteCompletePage`) bind against the canonical contract from day one and avoid a second mobile-side migration when slice 3 lands. The ADR-0013 mirror contract is satisfied: the TypeBox schema change and its Dart consumer ship in the same commit set.

## References

- Context7: `/fleaflet/flutter_map` (queried 2026-05-13 — TileLayer + OSM usage, attribution patterns).
- Context7: `/csdcorp/speech_to_text` (queried 2026-05-13).
- Context7: `/websites/pub_dev_google_mlkit_text_recognition` (queried 2026-05-13).
- `docs/08-ROADMAP-v2.md` — the active file this ADR locks in (v1 archived 2026-05-26 to `docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md` per ADR-0035).
- `docs/M2-COST-MODEL.md` — the cost ceiling enforced by this ADR's choices.
- `docs/M2-SLICE-CHECKLIST.md` — the per-slice execution discipline.
