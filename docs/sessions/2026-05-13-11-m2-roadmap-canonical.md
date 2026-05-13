# Session 2026-05-13-11 — m2-roadmap-canonical

## Metadata

- **Date**: 2026-05-13 (America/Sao_Paulo)
- **Sequence**: 11
- **Agent**: Claude Code (Opus 4.7, 1M ctx)
- **Human**: Eduardo
- **Topic**: Make `docs/08-ROADMAP.md` the single source of truth for M2; propagate the change across every related doc; lock library choices for slice 2 in ADRs.
- **Duration**: ~1h30m
- **Related ADRs**: ADR-0015 (M2 plan and library choices) and ADR-0016 (map + tile policy), both filed this session.
- **Related TODO items**: M2 slice 1 closed (in production as `v1.0.0`); slice 2 (Telas Core) is the next deliverable.

## Goal of the Session

Slice 1 shipped to production earlier in the day, and the user asked for a canonical roadmap to execute the rest of M2 from a new chat — "tudo deve se conectar e seguir a única fonte da verdade." The session's goal is to write that roadmap, propagate the decision through every doc that previously hinted at "M2 scope TBD," and capture the library choices for slice 2 in ADRs so the next agent doesn't have to re-derive them. Cost target communicated by the user: keep infrastructure extremely low while preserving security, scalability, and best practices.

## What Was Done

### Validated library choices via Context7 (Karpathy "Context7 mandatory")

Queried four targets to confirm 2026-current versions before writing the ADR:

- `/fleaflet/flutter_map` — `flutter_map` 8.x. Confirmed the OSM tile usage policy snippet (`userAgentPackageName` required, `RichAttributionWidget` for attribution, raster `TileLayer` URL template).
- `/csdcorp/speech_to_text` — version 7.x, on-device pt-BR support, score 94/100.
- `/websites/pub_dev_google_mlkit_text_recognition` — Latin-script on-device OCR.
- Did not find a maintained Node TS VRP solver via Context7; documented in ADR-0019 (to be filed in slice 3) that the path is in-process nearest-neighbor + 2-opt over a GraphHopper-built matrix, rather than an external library.

### Authored the canonical M2 roadmap

- **`docs/08-ROADMAP.md` rewritten end-to-end.** Status snapshot table, operating principles (slice-by-slice, Context7 mandatory, cost ceiling enforced, verify-before-claim-done), the locked seven slices with per-slice scope, sub-order, library list, file map, test plan, post-merge steps, and the read-first map for future agents.
- The roadmap calls out itself as the source of truth: "When any other doc disagrees with this file, this file wins, and the contradiction is a bug to fix in the same PR."

### Two new supporting docs

- **`docs/M2-SLICE-CHECKLIST.md`** — the rigid execution checklist used by every slice from slice 2 onward. Pre-flight (read order, Context7, brainstorming), branch and naming conventions, schema source-of-truth reminders, implementation discipline (Karpathy 4), verification steps (`flutter analyze`, `aapt2 dump permissions`, `apksigner verify`, real-device E2E with screenshot, curl evidence for any new backend endpoint), version bump rules, PR template body, post-merge ritual, "when something goes wrong" guidance, and cost-conscious choice criteria. **Encodes the slice 1 lessons** so we don't lose 45 min again on a missing `INTERNET` permission.
- **`docs/M2-COST-MODEL.md`** — current and projected infra cost; per-transaction unit economics; the explicit list of paid services we said no to and why; the decision rule for adding any paid service mid-M2. Operational target codified: ≤ BRL 200/month total infrastructure while ≤ 100 paying users. Triggers for re-evaluation captured.

### Two new ADRs

- **ADR-0015 — M2 Plan and Library Choices.** Locks the slice order (APK → Telas → VRP → Pix → Sentido casa → LGPD → Admin), names `docs/08-ROADMAP.md` as the canonical source of truth in the decision record, and pins the slice 2 libraries with rationale + cost.
- **ADR-0016 — Map and Tile Policy.** `flutter_map` 8.x + public OSM tiles with strict OSMF acceptable-use compliance (`userAgentPackageName`, `RichAttributionWidget`, no FMTC region download, no server-rendering); migration trigger to self-hosted tiles documented (resize droplet, install `tileserver-gl-light` + `openmaptiles` SP extract, point a subdomain at it, Cloudflare in front).

### Propagated the change across existing docs

- **`docs/04-FEATURES.md`** — feature map rewritten with status legend, M2 slice mapping per feature, M1 features marked ✅, F11 ("real-time subscriber counter") marked ⛔ removed because the pricing model changed to pay-per-route.
- **`docs/05-SCREENS.md`** — every screen tagged with its slice + sub-slice + prototype source file (`screens-a.jsx → ScreenLogin`, etc.) + status. Now serves as the cross-reference index for slice 2's screen catalogue.
- **`docs/02-ARCHITECTURE.md`** — Flow 3 rewritten for **pay-per-route** instead of monthly subscription; new Flow 4 (map + tile fetching + OSM compliance), Flow 5 (geocoding via Nominatim + rate-limit + cache), Flow 6 (external navigation hand-off via deep links).
- **`docs/01-PROJECT.md`** — milestone table updated (M1 ✅, M2 🟡), business model section rewritten for pay-per-route, points to the roadmap/checklist/cost-model trio as the M2 source of truth.
- **`docs/10-CHANGELOG.md`** — new 2026-05-13 entry capturing the roadmap reorg and the pricing model propagation, plus a sub-entry for slice 1 / ADR-0014.
- **`CLAUDE.md`** — "Current Focus" rewritten from M1 to "M2 / slice 2 next," with the locked seven-slice order embedded; "Onboarding Ritual" updated to point at the roadmap first and to read 5 session logs minimum (was 3); the read-first map matches the same order the new memory entry encodes.
- **`TODO.md`** — slice 1 marked ✅ shipped, slice 2 expanded into a sub-by-sub checklist matching the roadmap's "Sub 2a-e" structure, slices 3-7 referenced with one-liner each (full scope lives in the roadmap, not duplicated here).

### Project memory updated

- New memory entry `m2-source-of-truth-and-read-first-map.md` (project-scoped, `metadata.type: project`) so the next session that lands in this repo immediately learns the read order and the "ROADMAP wins" rule.
- `MEMORY.md` index updated with the new entry above the existing INTERNET-permission feedback.

## Decisions Made

1. **`docs/08-ROADMAP.md` is the single source of truth for M2.** Every other doc cross-references it; the agent acts from it. This is encoded in ADR-0015, in `CLAUDE.md`, in the project memory, and in the roadmap itself.
2. **Locked slice order:** APK (✅) → Telas Core → VRP → Pix → Sentido casa → LGPD → Admin. Confirmed with Eduardo in session 09; re-affirmed here in ADR-0015 with the alternatives discussed and rejected.
3. **Cost ceiling: ≤ BRL 200/month total infra while ≤ 100 paying users.** Codified in `docs/M2-COST-MODEL.md`. Every architectural choice in the slice 2-7 sections of the roadmap was justified against this.
4. **Slice 2 libraries pinned** in ADR-0015 with Context7-verified versions: `flutter_map` 8.x, `latlong2`, `geolocator` 14.x, `speech_to_text` 7.x, `google_mlkit_text_recognition` 0.x, `share_plus` 11.x. All on-device, zero per-request cost.
5. **Map tile source: public OSM tiles** with strict OSMF compliance (ADR-0016). Self-host migration documented as a numbered trigger, not as a goal — we ride free tier until traffic forces the move.
6. **Pricing model: pay-per-route** propagated throughout the docs. The session-9 / session-10 mentions had this right but the static docs still said "monthly subscription"; that contradiction is now resolved.
7. **No infra changes shipped in this PR** — only docs + ADRs + memory. Code-affecting changes go in slice 2's PR.

## Open Questions Left

- [ ] **Pricing — is BRL 25.90 the right Pix amount per route?** The original brief assumed monthly; the per-route amount was kept identical for simplicity. Worth confirming with the client before slice 4 ships, since the unit economics shift meaningfully.
- [ ] **Default external nav app (Google Maps vs Waze) for slice 2's "Iniciar navegação".** Document the policy in ADR-0017 when slice 2 starts the navigation shell. Tentative pick: Google Maps (multi-stop support), with Waze as a per-stop fallback.
- [ ] **Slice 4 hard prereqs** still pending Eduardo's side: the `.p12` mTLS cert from the Efí dashboard (sandbox + prod), the HMAC webhook secret. Captured in TODO.md and in the slice 4 section of the roadmap; not blocking until slice 4 starts.
- [ ] **Domain renewal date for `roteirizadorpro.com.br`** isn't on the calendar yet. Cost-model file calls for a reminder around 2026-04-01; Eduardo to set up.

## Files Changed

**Created:**

- `docs/08-ROADMAP.md` — rewrote in place; effectively new content.
- `docs/M2-SLICE-CHECKLIST.md`.
- `docs/M2-COST-MODEL.md`.
- `docs/decisions/0015-m2-plan-and-libraries.md`.
- `docs/decisions/0016-map-and-tile-policy.md`.
- `docs/sessions/2026-05-13-11-m2-roadmap-canonical.md` (this file).
- `~/.claude/projects/.../memory/m2-source-of-truth-and-read-first-map.md`.

**Modified:**

- `CLAUDE.md` — Current Focus M1 → M2 / slice 2; onboarding ritual; read-first map.
- `TODO.md` — slice 1 closed; slice 2 expanded into the sub-by-sub checklist matching the roadmap.
- `docs/01-PROJECT.md` — milestone table (M1 ✅, M2 🟡); business model rewritten for pay-per-route.
- `docs/02-ARCHITECTURE.md` — Flow 3 rewritten for pay-per-route; Flows 4-6 added.
- `docs/04-FEATURES.md` — feature map with status legend and slice mapping; F11 removed.
- `docs/05-SCREENS.md` — every screen tagged with slice + sub-slice + prototype source.
- `docs/10-CHANGELOG.md` — 2026-05-13 entry for the roadmap reorg + slice 1 ADR.
- `~/.claude/projects/.../memory/MEMORY.md` — index updated.

## Commits Pushed

To be appended after this commit lands. The session-end commit covers `TODO.md` + this session log + the index. The other 11 files above land in a single preceding commit (`docs: m2 roadmap made canonical`) on the same branch.

## Hand-off Notes for Next Session

- **Branch:** `chore/m2-roadmap-canonical` off `develop`. After the docs commit + the session-end commit, push and open a PR to `develop`.
- **Source of truth for everything M2-related:** `docs/08-ROADMAP.md`. **Read it before acting.** Cross-references are listed in the read-first map inside that file (and replicated in `CLAUDE.md` and in the new project memory entry).
- **Next slice = slice 2 (Telas Core).** Start with `superpowers:brainstorming` before opening any code file; the roadmap section "Slice 2 — Telas Core" lists the sub-order (2a Foundation → 2b Captura → 2c Manipulação → 2d Otimização mock + Navegação → 2e Periféricos) and the library set. `M2-SLICE-CHECKLIST.md` is the rigid checklist to follow.
- **Slice 2 prereqs** are all in the repo today: keystore in place, build script tested in slice 1, ADR-0016 specifies the OSM tile policy. New permissions to add to `src/main/AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `RECORD_AUDIO`, `CAMERA`. Slice 1 lesson — always declare them in `src/main/`, never only in `src/{debug,profile}/`.
- **Verification discipline:** before installing any new APK on a device, run `aapt2 dump permissions <apk>` and assert every expected permission is present. This is now a required step in `M2-SLICE-CHECKLIST.md`.

## Reference Material Used

- Context7: `/fleaflet/flutter_map` (queried 2026-05-13 — TileLayer + OSM usage + attribution).
- Context7: `/csdcorp/speech_to_text` (queried 2026-05-13).
- Context7: `/websites/pub_dev_google_mlkit_text_recognition` (queried 2026-05-13).
- OpenStreetMap Foundation — *Tile Usage Policy* (`https://operations.osmfoundation.org/policies/tiles/`).
- OpenStreetMap Foundation — *Nominatim Usage Policy* (`https://operations.osmfoundation.org/policies/nominatim/`).
- Existing project state: ADR-0014 (slice 1), session logs 09 + 10, `prototipo/Roteirizador Pro.html` + `prototipo/screens-{a,b,c,d,e}.jsx`, current production setup notes in `07-INFRA.md`.
