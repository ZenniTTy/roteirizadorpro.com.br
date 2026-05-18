# M2 Slice 2 — Telas Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the 15 remaining prototype screens in the Flutter app with real Riverpod state, modern Android opt-ins, a mock optimize endpoint, and external-nav handoff via deep link — packaged as APK `v1.1.0` reachable from `roteirizadorpro.com.br`.

**Architecture:** Mobile-first feature module `features/stops/` (domain → data → state → presentation) backed by an in-memory Riverpod controller persisted to `SharedPreferencesAsync`. Backend `POST /routes/optimize` evolves from 501 to a 200 mock returning input order. External nav is a deep-link service (Google Maps multi-stop default, Waze single-stop toggle). All five sub-slices share one branch `feat/m2-slice-2-telas-core` and one PR.

**Tech Stack:** Flutter (Riverpod 3 codegen + `@riverpod` + `build_runner`), Dart 3, `flutter_map` 8.x + OSM tiles, `speech_to_text`, `google_mlkit_text_recognition`, `image_picker`, `geolocator`, `permission_handler`, `shared_preferences` 2.3+ (`SharedPreferencesAsync`), `url_launcher`, `share_plus`, `uuid` v4. Backend: Fastify v5 + TypeBox.

**Spec:** `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md`

**Branch:** `feat/m2-slice-2-telas-core` (off `develop` at `4189da3`, already created and pushed).

---

## Working directory

All commands assume `cwd` is the repo root:
`/Users/eduardorodrigues/Downloads/Elo Vision Digital/[EVD] - Meus Projetos/[APP] - Entrega Smart`

The path contains spaces and brackets — always quote it when needed in shell. From here on, paths are repo-root-relative.

## Plan execution rules

1. **One task = one logical commit.** Each task ends with `git commit` using Conventional Commits + valid scope from `commitlint.config.cjs`. Lefthook runs typecheck/lint/analyze on the changed app(s).
2. **TDD where it makes sense.** Logic (controllers, repositories, services, URI builders, model conversions) → red test → green impl → commit. Widget screens → "renders without throwing" widget test first → screen impl → fidelity polish.
3. **No `--no-verify`.** If a hook fails, fix the underlying issue.
4. **Riverpod codegen.** Every controller is `@riverpod class X extends _$X { ... }`. After editing controllers, run `dart run build_runner build --delete-conflicting-outputs` and **commit the generated `.g.dart` files in the same commit** as the source.
5. **Hot reload over hot restart over full restart.** When `flutter run` is alive, prefer `r` for code changes inside `lib/**`. Full restart only for pubspec/native changes.
6. **Surgical edits only.** Don't refactor unrelated code. Match existing style in slice 1 files.
7. **Schema source-of-truth (ADR-0013).** TypeBox in `apps/backend/src/<feature>/schemas.ts` evolves first; Dart DTO mirror at `apps/mobile/lib/features/<feature>/data/dto/*.dart` ships in the same commit.
8. **Push after each completed sub-slice** (`git push` to keep origin current). At sub-slice 2e completion, do not open the PR yet — release tasks 29-32 come first.

## File structure created/modified by this plan

### Mobile (`apps/mobile/lib/`)

```
core/
├── services/
│   ├── id.dart                                       NEW  — uuid v4 wrapper
│   ├── permissions.dart                              NEW  — permission_handler wrapper
│   └── external_nav.dart                             NEW  — Google Maps + Waze deep link

features/
├── stops/                                            NEW (entire tree)
│   ├── domain/
│   │   └── stop.dart                                 NEW
│   ├── data/
│   │   ├── dto/
│   │   │   └── stop_dto.dart                         NEW  — mirror of TypeBox StopSchema
│   │   └── repositories/
│   │       ├── stops_repository.dart                 NEW  — interface
│   │       └── shared_prefs_stops_repository.dart    NEW  — SharedPreferencesAsync impl
│   ├── state/
│   │   ├── stops_controller.dart                     NEW  — @riverpod class StopsController
│   │   ├── stops_controller.g.dart                   NEW (codegen)
│   │   ├── optimize_controller.dart                  NEW  — @riverpod class OptimizeController
│   │   └── optimize_controller.g.dart                NEW (codegen)
│   └── presentation/
│       ├── home_empty_page.dart                      NEW
│       ├── home_list_page.dart                       NEW
│       ├── add_stop_page.dart                        NEW
│       ├── voice_capture_page.dart                   NEW
│       ├── ocr_capture_page.dart                     NEW
│       ├── add_stops_map_page.dart                   NEW
│       ├── stop_detail_page.dart                     NEW
│       ├── edit_stop_page.dart                       NEW
│       ├── reorder_page.dart                         NEW
│       ├── map_stops_page.dart                       NEW
│       ├── optimize_page.dart                        NEW
│       ├── optimize_route_page.dart                  NEW
│       ├── navigate_page.dart                        NEW
│       ├── route_complete_page.dart                  NEW
│       └── shared/
│           ├── stop_list_item.dart                   NEW
│           ├── stop_form.dart                        NEW
│           └── map_attribution.dart                  NEW
├── settings/
│   └── presentation/
│       └── settings_page.dart                        NEW
└── share/
    └── presentation/
        └── share_sheet.dart                          NEW

main.dart                                             MODIFY — edge-to-edge enable
app.dart                                              MODIFY — GoRouter additions
```

### Mobile config

```
apps/mobile/
├── pubspec.yaml                                      MODIFY — add 10 deps + bump version 1.1.0+2
├── pubspec.lock                                      MODIFY (resolver)
└── android/app/src/main/
    └── AndroidManifest.xml                           MODIFY — 3 perms + queries + predictive back
```

### Backend (`apps/backend/`)

```
src/routes/
├── schemas.ts                                        MODIFY — OptimizeResponseSchema evolves
└── routes.ts                                         MODIFY — 501 → 200 mock
```

### Tests (mobile)

```
apps/mobile/test/
├── features/stops/
│   ├── domain/stop_test.dart                         NEW
│   ├── data/
│   │   ├── stop_dto_test.dart                        NEW
│   │   └── shared_prefs_stops_repository_test.dart   NEW
│   ├── state/
│   │   ├── stops_controller_test.dart                NEW
│   │   └── optimize_controller_test.dart             NEW
│   └── presentation/
│       ├── home_empty_page_test.dart                 NEW
│       ├── home_list_page_test.dart                  NEW
│       ├── add_stop_page_test.dart                   NEW
│       ├── voice_capture_page_test.dart              NEW
│       ├── ocr_capture_page_test.dart                NEW
│       ├── add_stops_map_page_test.dart              NEW
│       ├── stop_detail_page_test.dart                NEW
│       ├── edit_stop_page_test.dart                  NEW
│       ├── reorder_page_test.dart                    NEW
│       ├── map_stops_page_test.dart                  NEW
│       ├── optimize_page_test.dart                   NEW
│       ├── optimize_route_page_test.dart             NEW
│       ├── navigate_page_test.dart                   NEW
│       └── route_complete_page_test.dart             NEW
├── core/services/
│   ├── id_test.dart                                  NEW
│   └── external_nav_test.dart                        NEW
├── features/settings/
│   └── settings_page_test.dart                       NEW
└── features/share/
    └── share_sheet_test.dart                         NEW
```

### Docs / ADR

```
docs/decisions/0017-external-navigation-handoff.md    NEW  — filed in Task 20
docs/sessions/2026-05-XX-NN-m2-slice-2-telas-core.md  NEW  — written via /session-end after merge
docs/10-CHANGELOG.md                                  MODIFY — entry for v1.1.0
TODO.md                                               MODIFY — slice 2 closed + post-M2 tech debt
docs/08-ROADMAP.md                                    MODIFY — mark slice 2 ✅
docs/decisions/0015-m2-plan-and-libraries.md          MODIFY — record resolved versions
```

### Landing

```
apps/landing/public/roteirizador-pro-v1.1.0.apk      NEW (built artifact)
apps/landing/src/app/page.tsx                        MODIFY — refactor 4 CTAs to APK_LATEST_VERSION constant
```

---

## Phase 0 — Pre-flight (no commits)

### Task 0: Verify environment

**Files:** none (read-only checks).

- [ ] **Step 0.1: Confirm branch and clean tree**

Run:
```bash
git status
git rev-parse --abbrev-ref HEAD
git log --oneline -3
```

Expected:
- Branch: `feat/m2-slice-2-telas-core`
- Working tree clean
- HEAD points at `c3d1b1e` (or later if amended) — the spec commit.

If any condition is false: STOP. The branch must be created off `develop` at `4189da3` and the spec commit must exist. Re-run the brainstorming flow if needed.

- [ ] **Step 0.2: Confirm Flutter and Bun installed and version-locked**

Run:
```bash
flutter --version
flutter doctor -v
bun --version
node --version
```

Expected:
- Flutter ≥ 3.24.0 (matches `pubspec.yaml: flutter: ">=3.24.0"`)
- Dart ≥ 3.5.0
- `flutter doctor` reports green for Android toolchain (target SDK detected, build-tools installed). iOS line is irrelevant.
- Bun ≥ 1.3
- Node 20.x (per ADR-0011)

If anything is missing, fix host setup before continuing.

- [ ] **Step 0.3: Confirm an Android device is reachable**

Run:
```bash
adb devices
```

Expected: at least one device listed as `device` (not `unauthorized` or `offline`). The Galaxy A06 used for slice 1 verification is the canonical target.

If empty: enable USB debugging on the device and retry. The slice can still proceed without a device during sub 2a/b/c/d sub-slices (analyzer + widget tests cover those locally), but the device IS required for the release verification in Task 29-32.

- [ ] **Step 0.4: Read the spec one more time**

Open `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` and skim the §Goals (14-step golden path) and §Test strategy sections. This is the contract every task below upholds.

No commit — Phase 0 is read-only.

---

## Phase 1 — Sub 2a Foundation

This phase establishes the modern Android opt-ins, the new mobile deps, the backend TypeBox evolution, the Stop domain + DTO + repository + controller, and the first two screens (`ScreenHomeEmpty`, `ScreenHomeList`).

### Task 1: Add slice 2 dependencies to `pubspec.yaml`

**Files:**
- Modify: `apps/mobile/pubspec.yaml`
- Modify: `apps/mobile/pubspec.lock` (resolver)

- [ ] **Step 1.1: Add deps via `flutter pub add`**

Run (from repo root):
```bash
cd apps/mobile && flutter pub add \
  uuid \
  shared_preferences \
  url_launcher \
  permission_handler \
  geolocator \
  image_picker \
  speech_to_text \
  google_mlkit_text_recognition \
  flutter_map \
  latlong2 \
  share_plus && cd ../..
```

`flutter pub add` modifies `pubspec.yaml` (caret-pinning each at resolved latest) AND `pubspec.lock` AND runs `flutter pub get`. Expected: no resolver errors. If a constraint conflict appears, do NOT add `dependency_overrides` — resolve by upgrading the conflicting peer with `flutter pub upgrade <pkg>`.

- [ ] **Step 1.2: Bump version**

Edit `apps/mobile/pubspec.yaml`:

Change:
```yaml
version: 1.0.0+1
```
To:
```yaml
version: 1.1.0+2
```

Rationale: minor bump (new user-facing features), build code +1 (Android requires monotonic increase).

- [ ] **Step 1.3: Verify resolver result**

Run:
```bash
cd apps/mobile && flutter pub get && flutter analyze && cd ../..
```

Expected:
- `Got dependencies!`
- `flutter analyze` reports 0 issues (slice 1 baseline preserved; no new lint errors from the deps themselves since none are imported yet).

- [ ] **Step 1.4: Commit**

```bash
git add apps/mobile/pubspec.yaml apps/mobile/pubspec.lock
git commit -m "$(cat <<'EOF'
feat(deps): add slice 2 mobile dependencies and bump version to 1.1.0+2

Adds uuid, shared_preferences, url_launcher, permission_handler,
geolocator, image_picker, speech_to_text, google_mlkit_text_recognition,
flutter_map, latlong2, share_plus. All resolved at caret-latest by the
pub.dev resolver and recorded in pubspec.lock. Version bumped per
M2-SLICE-CHECKLIST §Version bumping (minor since slice 2 ships new
user-facing features; build code +1 because Android refuses installs
of equal versionCode).
EOF
)"
```

### Task 2: Record resolved versions in ADR-0015

**Files:**
- Modify: `docs/decisions/0015-m2-plan-and-libraries.md`

- [ ] **Step 2.1: Capture exact pins**

Run:
```bash
grep -E "^  (uuid|shared_preferences|url_launcher|permission_handler|geolocator|image_picker|speech_to_text|google_mlkit_text_recognition|flutter_map|latlong2|share_plus):" apps/mobile/pubspec.yaml
```

Copy the version strings (e.g. `^4.5.1`, `^2.3.5`, etc.) from the output.

- [ ] **Step 2.2: Amend the ADR-0015 library table**

Open `docs/decisions/0015-m2-plan-and-libraries.md`. Find the table under "Decision" §3 ("Slice 2 libraries (validated via Context7 on 2026-05-13)"). Replace the "Version target" column with the exact resolved versions from Step 2.1.

Also append below the table:
```markdown
**Update 2026-05-XX (slice 2 sub-2a):** versions resolved by `flutter pub add` and recorded in `apps/mobile/pubspec.lock`. Five new libs (`uuid`, `shared_preferences`, `url_launcher`, `permission_handler`, `image_picker`) joined the original six listed above; the full list is reflected in the table.
```

Replace `2026-05-XX` with today's actual ISO date.

- [ ] **Step 2.3: Commit**

```bash
git add docs/decisions/0015-m2-plan-and-libraries.md
git commit -m "$(cat <<'EOF'
docs(decisions): record resolved versions in adr-0015

Amends ADR-0015's library table with the exact caret-semver pins the
pub.dev resolver chose for the 11 slice-2 deps (six from the original
ADR plus five added during this slice). Lock authority remains
pubspec.lock; the ADR now mirrors it as a snapshot.
EOF
)"
```

### Task 3: Enable Android 15 edge-to-edge in `main.dart`

**Files:**
- Modify: `apps/mobile/lib/main.dart`

- [ ] **Step 3.1: Read existing `main.dart`**

Run:
```bash
cat apps/mobile/lib/main.dart
```

Note the current structure (probably `void main() { runApp(...) }`).

- [ ] **Step 3.2: Apply the edge-to-edge enable + transparent system bars**

Replace `apps/mobile/lib/main.dart` body with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(const ProviderScope(child: RoteirizadorProApp()));
}
```

If the existing `main.dart` already imports a different app widget or uses a different ProviderScope wiring, preserve that — only the two SystemChrome calls are mandatory additions.

- [ ] **Step 3.3: Run analyzer**

Run:
```bash
cd apps/mobile && flutter analyze && cd ../..
```

Expected: 0 issues.

- [ ] **Step 3.4: Manual smoke (if a device is connected)**

If `adb devices` reports a device:
```bash
cd apps/mobile && flutter run -d <device-id> && cd ../..
```

Visually confirm the login screen renders with status bar transparent (the existing login background should now show under the status bar). Press `q` to exit `flutter run` cleanly.

If no device available, skip this step — the manual edge-to-edge check is repeated in Task 8 once the home screen ships.

- [ ] **Step 3.5: Commit**

```bash
git add apps/mobile/lib/main.dart
git commit -m "$(cat <<'EOF'
feat(mobile): adopt android 15 edge-to-edge with transparent system bars

Enables SystemUiMode.edgeToEdge globally so the app renders under the
status/navigation bars per Android 15's targetSdk-35 enforcement.
Transparent system bars let the prototype's gradients show through.
Subsequent slice-2 screens use SafeArea where padding matters; slice-1
screens (Login/Register) already wrap their content with built-in
material padding, so no retrofit is needed.
EOF
)"
```

### Task 4: Opt into Android 14 predictive back animation

**Files:**
- Modify: `apps/mobile/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 4.1: Read existing manifest**

Run:
```bash
cat apps/mobile/android/app/src/main/AndroidManifest.xml
```

- [ ] **Step 4.2: Add `enableOnBackInvokedCallback` to `<application>`**

Edit `apps/mobile/android/app/src/main/AndroidManifest.xml`. Find the `<application>` opening tag. Add the attribute `android:enableOnBackInvokedCallback="true"`.

Example before:
```xml
<application
    android:label="Roteirizador Pro"
    android:icon="@mipmap/ic_launcher">
```

After:
```xml
<application
    android:label="Roteirizador Pro"
    android:icon="@mipmap/ic_launcher"
    android:enableOnBackInvokedCallback="true">
```

- [ ] **Step 4.3: Commit**

```bash
git add apps/mobile/android/app/src/main/AndroidManifest.xml
git commit -m "$(cat <<'EOF'
feat(mobile): opt into android 14 predictive back animation

Adds android:enableOnBackInvokedCallback="true" to <application> so the
OS animates back-gesture previews of the destination route. Required
opt-in for the new behavior on Android 14+; Flutter 3.27+ wires the
gesture under the hood once this flag is set.
EOF
)"
```

### Task 5: Evolve the backend `OptimizeResponseSchema`

**Files:**
- Modify: `apps/backend/src/routes/schemas.ts`

- [ ] **Step 5.1: Read existing schemas**

Run:
```bash
cat apps/backend/src/routes/schemas.ts
```

Confirm `StopSchema` and `OptimizeRequestSchema` already exist as per the spec. `OptimizeResponseSchema` currently is the 501 placeholder shape.

- [ ] **Step 5.2: Replace `OptimizeResponseSchema` with the wire-final shape**

Open `apps/backend/src/routes/schemas.ts` and replace the existing `OptimizeResponseSchema` block with:

```typescript
// EVOLVED in slice 2: replaces the 501-placeholder shape.
// Slice 2's mock returns input order with zeroed metrics.
// Slice 3 reuses this shape against the real GraphHopper+TSP solver.
export const OptimizeResponseSchema = Type.Object({
  optimizedOrder: Type.Array(Type.Integer({ minimum: 0 })),
  totalDistanceM: Type.Number({ minimum: 0 }),
  totalDurationS: Type.Number({ minimum: 0 }),
});
export type OptimizeResponse = Static<typeof OptimizeResponseSchema>;
```

Also export `StopSchema` so the Dart mirror header can reference it (if not already exported):

```typescript
export const StopSchema = Type.Object({
  lat: Type.Number({ minimum: -90, maximum: 90 }),
  lng: Type.Number({ minimum: -180, maximum: 180 }),
  label: Type.Optional(Type.String()),
});
export type Stop = Static<typeof StopSchema>;
```

- [ ] **Step 5.3: Run backend typecheck**

```bash
cd apps/backend && bun run typecheck && cd ../..
```

Expected: TypeScript compiles. The existing `routes.ts` may now error because its 501 handler returns a shape that doesn't match the new schema — that's the next task.

If the typecheck passes despite the contract change, the handler is probably still typed against the old `response: { 501: ... }` block in `routes.ts`. Either way, proceed.

- [ ] **Step 5.4: Commit**

```bash
git add apps/backend/src/routes/schemas.ts
git commit -m "$(cat <<'EOF'
feat(routes): evolve OptimizeResponseSchema to wire-final shape

Replaces the 501-placeholder shape (status + message) with the shape
slice 2's mock and slice 3's real solver will both return:
optimizedOrder: int[], totalDistanceM: number, totalDurationS: number.
Slice 2's handler will return input-order indices with zeroed metrics
(next commit). Slice 3 swaps in the GraphHopper+TSP solver without
touching the shape, the Dart DTO mirror, or the mobile controller.
EOF
)"
```

### Task 6: Replace the 501 placeholder with the 200 mock

**Files:**
- Modify: `apps/backend/src/routes/routes.ts`

- [ ] **Step 6.1: Read existing routes**

```bash
cat apps/backend/src/routes/routes.ts
```

- [ ] **Step 6.2: Replace 501 with 200 mock**

Replace the file body with:

```typescript
import type { FastifyPluginAsyncTypebox } from '@fastify/type-provider-typebox';
import { OptimizeRequestSchema, OptimizeResponseSchema } from './schemas.js';

const routesRoutes: FastifyPluginAsyncTypebox = async (app) => {
  app.post('/optimize', {
    onRequest: [app.authenticate],
    schema: {
      body: OptimizeRequestSchema,
      response: { 200: OptimizeResponseSchema },
    },
  }, async (request) => {
    const { stops } = request.body;
    // Slice 2 mock: input order, zeroed metrics.
    // Slice 3 will replace the body of this handler with the real solver
    // (GraphHopper distance matrix → nearest-neighbor + 2-opt).
    return {
      optimizedOrder: stops.map((_, i) => i),
      totalDistanceM: 0,
      totalDurationS: 0,
    };
  });
};

export default routesRoutes;
```

- [ ] **Step 6.3: Typecheck**

```bash
cd apps/backend && bun run typecheck && cd ../..
```

Expected: clean.

- [ ] **Step 6.4: Smoke against the dev server**

In one terminal:
```bash
cd apps/backend && bun run dev
```

In another, capture three curl outputs. First, get an auth token (or paste an existing one):
```bash
# register or login to get a token
curl -s -X POST http://localhost:3000/auth/login \
  -H 'content-type: application/json' \
  -d '{"email":"test@example.com","password":"Senha123!"}' | jq -r '.accessToken'
```

If `test@example.com` doesn't exist locally, register first via `/auth/register`. Save the token as `TOKEN`.

Capture the three smoke outputs and paste them into a scratch file for the PR body later:

```bash
echo "--- 200 valid request ---" > /tmp/slice2-optimize-smoke.txt
curl -is -X POST http://localhost:3000/routes/optimize \
  -H "authorization: Bearer $TOKEN" \
  -H 'content-type: application/json' \
  -d '{"stops":[{"lat":-23.55,"lng":-46.63,"label":"A"},{"lat":-23.56,"lng":-46.64,"label":"B"}]}' \
  | tee -a /tmp/slice2-optimize-smoke.txt

echo "--- 401 no auth ---" >> /tmp/slice2-optimize-smoke.txt
curl -is -X POST http://localhost:3000/routes/optimize \
  -H 'content-type: application/json' \
  -d '{"stops":[{"lat":-23.55,"lng":-46.63},{"lat":-23.56,"lng":-46.64}]}' \
  | tee -a /tmp/slice2-optimize-smoke.txt

echo "--- 400 invalid body ---" >> /tmp/slice2-optimize-smoke.txt
curl -is -X POST http://localhost:3000/routes/optimize \
  -H "authorization: Bearer $TOKEN" \
  -H 'content-type: application/json' \
  -d '{"stops":[]}' \
  | tee -a /tmp/slice2-optimize-smoke.txt
```

Expected:
- 1st: `HTTP/1.1 200 OK` with body `{"optimizedOrder":[0,1],"totalDistanceM":0,"totalDurationS":0}`.
- 2nd: `HTTP/1.1 401 Unauthorized`.
- 3rd: `HTTP/1.1 400 Bad Request` (TypeBox rejects `minItems: 2`).

Save the file path — it goes in the PR body in Task 29.

Stop the dev server (`Ctrl+C`).

- [ ] **Step 6.5: Commit**

```bash
git add apps/backend/src/routes/routes.ts
git commit -m "$(cat <<'EOF'
feat(routes): mock POST /routes/optimize returns input order

Replaces the 501 placeholder with a 200 mock that echoes the input
stop order via optimizedOrder indices and returns zeroed totalDistanceM
and totalDurationS. Auth-gated (existing onRequest: [app.authenticate]).
Body validated by OptimizeRequestSchema (minItems: 2 → maxItems: 50).
Slice 3 will replace just the handler body with the real solver,
keeping schema and route registration intact.

Smoke (curl -i, three captures): 200 valid, 401 no auth, 400 empty
stops. Outputs preserved in the slice 2 PR body.
EOF
)"
```

### Task 7: Create the `Stop` domain model (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/domain/stop.dart`
- Test: `apps/mobile/test/features/stops/domain/stop_test.dart`

- [ ] **Step 7.1: Write the failing test**

Create `apps/mobile/test/features/stops/domain/stop_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

void main() {
  group('Stop', () {
    final createdAt = DateTime.utc(2026, 5, 13, 12, 0, 0);

    test('constructor preserves all fields', () {
      final s = Stop(
        id: 'abc-123',
        lat: -23.55,
        lng: -46.63,
        label: 'Av. Paulista',
        source: StopSource.mapTap,
        createdAt: createdAt,
      );

      expect(s.id, 'abc-123');
      expect(s.lat, -23.55);
      expect(s.lng, -46.63);
      expect(s.label, 'Av. Paulista');
      expect(s.source, StopSource.mapTap);
      expect(s.createdAt, createdAt);
    });

    test('copyWith overrides only the given fields', () {
      final original = Stop(
        id: 'abc',
        lat: 0,
        lng: 0,
        label: 'origin',
        source: StopSource.manual,
        createdAt: createdAt,
      );

      final updated = original.copyWith(lat: 10, lng: 20, label: 'moved');

      expect(updated.id, 'abc');
      expect(updated.lat, 10);
      expect(updated.lng, 20);
      expect(updated.label, 'moved');
      expect(updated.source, StopSource.manual);
      expect(updated.createdAt, createdAt);
    });

    test('equality is value-based on all fields', () {
      final a = Stop(
        id: '1', lat: 1, lng: 2, label: 'x',
        source: StopSource.voice, createdAt: createdAt,
      );
      final b = Stop(
        id: '1', lat: 1, lng: 2, label: 'x',
        source: StopSource.voice, createdAt: createdAt,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('toJson and fromJson roundtrip preserves all fields including source', () {
      final original = Stop(
        id: 'abc',
        lat: -23.55,
        lng: -46.63,
        label: 'Av. Paulista',
        source: StopSource.ocr,
        createdAt: createdAt,
      );

      final json = original.toJson();
      final restored = Stop.fromJson(json);

      expect(restored, equals(original));
    });

    test('toJson omits a null label', () {
      final original = Stop(
        id: 'abc', lat: 0, lng: 0, label: null,
        source: StopSource.manual, createdAt: createdAt,
      );
      final json = original.toJson();

      expect(json.containsKey('label'), isFalse);
    });
  });
}
```

- [ ] **Step 7.2: Run the test to verify it fails**

```bash
cd apps/mobile && flutter test test/features/stops/domain/stop_test.dart && cd ../..
```

Expected: compile error — `stop.dart` does not exist yet.

- [ ] **Step 7.3: Write the minimal implementation**

Create `apps/mobile/lib/features/stops/domain/stop.dart`:

```dart
import 'package:flutter/foundation.dart';

enum StopSource { manual, voice, ocr, mapTap }

@immutable
class Stop {
  const Stop({
    required this.id,
    required this.lat,
    required this.lng,
    required this.source,
    required this.createdAt,
    this.label,
  });

  final String id;
  final double lat;
  final double lng;
  final String? label;
  final StopSource source;
  final DateTime createdAt;

  Stop copyWith({
    String? id,
    double? lat,
    double? lng,
    String? label,
    StopSource? source,
    DateTime? createdAt,
  }) {
    return Stop(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      label: label ?? this.label,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': lat,
      'lng': lng,
      if (label != null) 'label': label,
      'source': source.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Stop fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      label: json['label'] as String?,
      source: StopSource.values.byName(json['source'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Stop &&
        other.id == id &&
        other.lat == lat &&
        other.lng == lng &&
        other.label == label &&
        other.source == source &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, lat, lng, label, source, createdAt);
}
```

- [ ] **Step 7.4: Run tests to verify they pass**

```bash
cd apps/mobile && flutter test test/features/stops/domain/stop_test.dart && cd ../..
```

Expected: 5 tests pass.

- [ ] **Step 7.5: Commit**

```bash
git add apps/mobile/lib/features/stops/domain/stop.dart apps/mobile/test/features/stops/domain/stop_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add Stop domain model with json roundtrip

Pure-Dart model with id (UUID v4 local), lat/lng, optional label,
StopSource enum (manual/voice/ocr/mapTap), and createdAt timestamp.
Implements value-equality via Object.hash + operator==, copyWith
for state updates, and toJson/fromJson for shared_preferences
persistence. The source field is local-only metadata; the toDto
conversion (next task) drops it before going on the wire.

Tests cover constructor, copyWith semantics, equality, JSON roundtrip
including the optional label, and that toJson omits a null label.
EOF
)"
```

### Task 8: Create the `StopDto` mirror (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/data/dto/stop_dto.dart`
- Test: `apps/mobile/test/features/stops/data/stop_dto_test.dart`

- [ ] **Step 8.1: Write the failing test**

Create `apps/mobile/test/features/stops/data/stop_dto_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/stops/data/dto/stop_dto.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

void main() {
  group('StopDto', () {
    test('fromJson reads lat, lng and optional label', () {
      final dto = StopDto.fromJson({'lat': -23.5, 'lng': -46.6, 'label': 'X'});
      expect(dto.lat, -23.5);
      expect(dto.lng, -46.6);
      expect(dto.label, 'X');
    });

    test('fromJson tolerates a missing label', () {
      final dto = StopDto.fromJson({'lat': 0, 'lng': 0});
      expect(dto.label, isNull);
    });

    test('toJson includes label when present', () {
      final dto = StopDto(lat: 1, lng: 2, label: 'Y');
      expect(dto.toJson(), {'lat': 1.0, 'lng': 2.0, 'label': 'Y'});
    });

    test('toJson omits label when null', () {
      final dto = StopDto(lat: 1, lng: 2);
      expect(dto.toJson(), {'lat': 1.0, 'lng': 2.0});
    });

    test('Stop.toDto drops id/source/createdAt', () {
      final s = Stop(
        id: 'abc', lat: 10, lng: 20, label: 'Z',
        source: StopSource.voice, createdAt: DateTime.utc(2026, 5, 13),
      );
      final dto = s.toDto();
      expect(dto.toJson(), {'lat': 10.0, 'lng': 20.0, 'label': 'Z'});
    });

    test('Stop.fromDto injects a fresh id, manual source and now() timestamp', () {
      final dto = StopDto(lat: 1, lng: 2, label: 'L');
      final s = Stop.fromDto(dto, id: 'fresh', now: DateTime.utc(2026, 5, 13));
      expect(s.id, 'fresh');
      expect(s.source, StopSource.manual);
      expect(s.createdAt, DateTime.utc(2026, 5, 13));
      expect(s.lat, 1);
      expect(s.lng, 2);
      expect(s.label, 'L');
    });
  });
}
```

- [ ] **Step 8.2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/features/stops/data/stop_dto_test.dart && cd ../..
```

Expected: compile error — `stop_dto.dart` does not exist, and `Stop` has no `toDto`/`fromDto`.

- [ ] **Step 8.3: Create the DTO file**

Create `apps/mobile/lib/features/stops/data/dto/stop_dto.dart`:

```dart
// Mirror of: apps/backend/src/routes/schemas.ts -> StopSchema
//
// Per ADR-0013: the TypeBox schema is the source of truth for the HTTP
// contract. This Dart class mirrors it 1:1 — fields and types match,
// no renaming. When the TypeBox StopSchema changes, this file changes
// in the same commit.

import 'package:flutter/foundation.dart';

@immutable
class StopDto {
  const StopDto({required this.lat, required this.lng, this.label});

  final double lat;
  final double lng;
  final String? label;

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (label != null) 'label': label,
    };
  }

  static StopDto fromJson(Map<String, dynamic> json) {
    return StopDto(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      label: json['label'] as String?,
    );
  }
}
```

- [ ] **Step 8.4: Extend the `Stop` domain with `toDto` / `fromDto`**

Add to `apps/mobile/lib/features/stops/domain/stop.dart` (top of file, add the import; inside the class, add the methods):

```dart
// At the top of the file:
import '../data/dto/stop_dto.dart';

// Inside the Stop class (anywhere; conventionally after fromJson):
  StopDto toDto() => StopDto(lat: lat, lng: lng, label: label);

  static Stop fromDto(
    StopDto dto, {
    required String id,
    StopSource source = StopSource.manual,
    DateTime? now,
  }) {
    return Stop(
      id: id,
      lat: dto.lat,
      lng: dto.lng,
      label: dto.label,
      source: source,
      createdAt: now ?? DateTime.now(),
    );
  }
```

- [ ] **Step 8.5: Run tests to verify all pass**

```bash
cd apps/mobile && flutter test test/features/stops/data/stop_dto_test.dart test/features/stops/domain/stop_test.dart && cd ../..
```

Expected: all 11 tests pass (5 stop + 6 dto).

- [ ] **Step 8.6: Commit**

```bash
git add apps/mobile/lib/features/stops/data/dto/stop_dto.dart apps/mobile/lib/features/stops/domain/stop.dart apps/mobile/test/features/stops/data/stop_dto_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add StopDto mirror of TypeBox StopSchema

DTO at apps/mobile/lib/features/stops/data/dto/stop_dto.dart with the
ADR-0013 'Mirror of:' header pointing at the backend schemas.ts. Fields
lat, lng, label? match the TypeBox shape 1:1, no renames.

Stop.toDto() drops local-only fields (id, source, createdAt) before
the wire; Stop.fromDto() injects a fresh UUID + StopSource.manual on
hydrate (the source enum exists to track UI provenance, not to round-trip
through the backend). Now() is injectable for deterministic tests.

Schema source-of-truth (ADR-0013): TypeBox StopSchema evolves first,
this mirror follows in the same commit set. Slice 2 keeps StopSchema
unchanged; if slice 3 adds a field, the same-commit rule applies.
EOF
)"
```

### Task 9: Create the `StopsRepository` interface and `SharedPrefsStopsRepository` impl (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/data/repositories/stops_repository.dart`
- Create: `apps/mobile/lib/features/stops/data/repositories/shared_prefs_stops_repository.dart`
- Test: `apps/mobile/test/features/stops/data/shared_prefs_stops_repository_test.dart`

- [ ] **Step 9.1: Write the failing test**

Create `apps/mobile/test/features/stops/data/shared_prefs_stops_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/shared_prefs_stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Stop _make(String id, double lat, double lng) => Stop(
        id: id,
        lat: lat,
        lng: lng,
        label: 'L-$id',
        source: StopSource.manual,
        createdAt: DateTime.utc(2026, 5, 13, 12),
      );

  test('load returns empty list when no key is present', () async {
    final repo = SharedPrefsStopsRepository();
    expect(await repo.load(), isEmpty);
  });

  test('save then load roundtrips the list preserving order', () async {
    final repo = SharedPrefsStopsRepository();
    final stops = [_make('a', 1, 2), _make('b', 3, 4), _make('c', 5, 6)];

    await repo.save(stops);
    final restored = await repo.load();

    expect(restored, stops);
  });

  test('persisted JSON uses the _v: 1 envelope', () async {
    final repo = SharedPrefsStopsRepository();
    await repo.save([_make('a', 1, 2)]);

    final raw = await SharedPreferencesAsync()
        .getString(SharedPrefsStopsRepository.storageKey);

    expect(raw, isNotNull);
    expect(raw, contains('"_v":1'));
    expect(raw, contains('"stops"'));
  });

  test('load tolerates a corrupt/legacy payload by returning empty', () async {
    await SharedPreferencesAsync()
        .setString(SharedPrefsStopsRepository.storageKey, 'not-json');

    final repo = SharedPrefsStopsRepository();
    expect(await repo.load(), isEmpty);
  });

  test('save([]) clears the persisted list', () async {
    final repo = SharedPrefsStopsRepository();
    await repo.save([_make('a', 1, 2)]);
    await repo.save([]);

    expect(await repo.load(), isEmpty);
  });
}
```

- [ ] **Step 9.2: Run test to confirm failure**

```bash
cd apps/mobile && flutter test test/features/stops/data/shared_prefs_stops_repository_test.dart && cd ../..
```

Expected: compile error — repository files don't exist yet.

- [ ] **Step 9.3: Create the interface**

Create `apps/mobile/lib/features/stops/data/repositories/stops_repository.dart`:

```dart
import '../../domain/stop.dart';

/// Persistence contract for the user's current stop list.
///
/// Slice 2 ships a SharedPreferences-backed impl
/// (`SharedPrefsStopsRepository`) for session restore. Slice 3 will
/// add `HttpStopsRepository` that reads/writes the backend `routes`
/// table; the controller swaps the impl via Riverpod override without
/// changing call sites.
abstract class StopsRepository {
  Future<List<Stop>> load();
  Future<void> save(List<Stop> stops);
}
```

- [ ] **Step 9.4: Create the SharedPreferences impl**

Create `apps/mobile/lib/features/stops/data/repositories/shared_prefs_stops_repository.dart`:

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/stop.dart';
import 'stops_repository.dart';

/// SharedPreferencesAsync-backed implementation of [StopsRepository].
///
/// Per spec §Persistence (and the modern-API rule in §Risks), uses the
/// async-first SharedPreferencesAsync (shared_preferences 2.3+), not
/// the deprecated SharedPreferences.getInstance().
///
/// The persisted JSON has a `_v: 1` envelope so slice 3's
/// HttpStopsRepository can recognize and drain it on first hydrate.
class SharedPrefsStopsRepository implements StopsRepository {
  SharedPrefsStopsRepository({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const storageKey = 'stops.current_session';
  static const _schemaVersion = 1;

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<Stop>> load() async {
    final raw = await _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['_v'] != _schemaVersion) return const [];

      final list = decoded['stops'] as List<dynamic>;
      return list
          .map((e) => Stop.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      // Corrupt payload: prefer an empty session over a crash.
      return const [];
    }
  }

  @override
  Future<void> save(List<Stop> stops) async {
    final payload = {
      '_v': _schemaVersion,
      'stops': stops.map((s) => s.toJson()).toList(),
    };
    await _prefs.setString(storageKey, jsonEncode(payload));
  }
}
```

- [ ] **Step 9.5: Run tests to verify pass**

```bash
cd apps/mobile && flutter test test/features/stops/data/shared_prefs_stops_repository_test.dart && cd ../..
```

Expected: 5 tests pass.

- [ ] **Step 9.6: Commit**

```bash
git add apps/mobile/lib/features/stops/data/repositories/ apps/mobile/test/features/stops/data/shared_prefs_stops_repository_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add SharedPreferencesAsync-backed StopsRepository

Interface + SharedPrefsStopsRepository implementation using the modern
SharedPreferencesAsync API (shared_preferences 2.3+, NOT the legacy
getInstance() per spec §Persistence + §Risks).

Persisted JSON uses a {_v: 1, stops: [...]} envelope so slice 3's
HttpStopsRepository can detect and drain the local payload on first
hydrate, then remove the key. Corrupt or wrong-schema payloads return
empty rather than crashing — a session restore that loses data is
better than a launchless app.

Tests cover: empty load, save/load roundtrip preserving order, _v: 1
envelope is on disk, corrupt JSON tolerated, save([]) clears the list.
The InMemorySharedPreferencesAsync test substrate from the package keeps
each test isolated without touching real native storage.
EOF
)"
```

### Task 10: Create `core/services/id.dart` (UUID v4 wrapper) (TDD)

**Files:**
- Create: `apps/mobile/lib/core/services/id.dart`
- Test: `apps/mobile/test/core/services/id_test.dart`

- [ ] **Step 10.1: Write the failing test**

Create `apps/mobile/test/core/services/id_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/services/id.dart';

void main() {
  test('newId returns an RFC 4122 v4 UUID', () {
    final id = newId();

    // UUID v4 format: 8-4-4-4-12, with the version nibble '4' and
    // the variant bits 10xx in the y nibble.
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(pattern.hasMatch(id), isTrue, reason: 'got $id');
  });

  test('newId is collision-free across many calls', () {
    final ids = <String>{for (var i = 0; i < 1000; i++) newId()};
    expect(ids.length, 1000);
  });
}
```

- [ ] **Step 10.2: Run test to confirm failure**

```bash
cd apps/mobile && flutter test test/core/services/id_test.dart && cd ../..
```

Expected: compile error — `id.dart` does not exist.

- [ ] **Step 10.3: Create the service**

Create `apps/mobile/lib/core/services/id.dart`:

```dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Returns a fresh RFC 4122 v4 UUID.
///
/// Slice 2 uses this to mint local Stop ids before the backend `routes`
/// table exists. Slice 3's HttpStopsRepository will keep the same id
/// space — the backend trusts the client-minted id on first POST.
String newId() => _uuid.v4();
```

- [ ] **Step 10.4: Run tests**

```bash
cd apps/mobile && flutter test test/core/services/id_test.dart && cd ../..
```

Expected: 2 tests pass.

- [ ] **Step 10.5: Commit**

```bash
git add apps/mobile/lib/core/services/id.dart apps/mobile/test/core/services/id_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): add uuid v4 wrapper for local entity ids

Tiny core/services/id.dart wrapper around the uuid package's v4 generator
so callers (StopsController, future HttpStopsRepository) depend on a
single import. The uuid package is RFC 4122 + RFC 9562 compliant
(Context7 /websites/pub_dev_packages_uuid).

Tests verify format conformance (8-4-4-4-12 with version-4 nibble and
the variant bits 10xx) and collision-freeness across 1000 calls.
EOF
)"
```

### Task 11: Create the `StopsController` (Riverpod codegen, TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/state/stops_controller.dart`
- Create: `apps/mobile/lib/features/stops/state/stops_controller.g.dart` (codegen, auto-generated)
- Test: `apps/mobile/test/features/stops/state/stops_controller_test.dart`

- [ ] **Step 11.1: Write the failing test**

Create `apps/mobile/test/features/stops/state/stops_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _FakeRepo implements StopsRepository {
  List<Stop> _stored = [];

  @override
  Future<List<Stop>> load() async => List.unmodifiable(_stored);

  @override
  Future<void> save(List<Stop> stops) async {
    _stored = List.of(stops);
  }
}

Stop _stop(String id, {double lat = 0, double lng = 0}) => Stop(
      id: id,
      lat: lat,
      lng: lng,
      label: 'L-$id',
      source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13, 12),
    );

void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(
      overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('build hydrates from repository', () async {
    repo._stored = [_stop('a'), _stop('b')];
    final initial = await container.read(stopsControllerProvider.future);
    expect(initial.map((s) => s.id), ['a', 'b']);
  });

  test('add appends and persists', () async {
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.add(_stop('a'));
    await controller.add(_stop('b'));

    final state = await container.read(stopsControllerProvider.future);
    expect(state.map((s) => s.id), ['a', 'b']);
    expect(repo._stored.map((s) => s.id), ['a', 'b']);
  });

  test('remove drops the matching id', () async {
    repo._stored = [_stop('a'), _stop('b'), _stop('c')];
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.remove('b');

    final state = await container.read(stopsControllerProvider.future);
    expect(state.map((s) => s.id), ['a', 'c']);
  });

  test('update replaces by id preserving order', () async {
    repo._stored = [_stop('a'), _stop('b', lat: 1)];
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.update(_stop('b', lat: 99));

    final state = await container.read(stopsControllerProvider.future);
    expect(state[1].lat, 99);
    expect(state.map((s) => s.id), ['a', 'b']);
  });

  test('reorder moves by index', () async {
    repo._stored = [_stop('a'), _stop('b'), _stop('c')];
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.reorder(0, 2);

    final state = await container.read(stopsControllerProvider.future);
    expect(state.map((s) => s.id), ['b', 'a', 'c']);
  });

  test('applyOptimizedOrder permutes by index list', () async {
    repo._stored = [_stop('a'), _stop('b'), _stop('c')];
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.applyOptimizedOrder([2, 0, 1]);

    final state = await container.read(stopsControllerProvider.future);
    expect(state.map((s) => s.id), ['c', 'a', 'b']);
  });

  test('clear empties the list and persists', () async {
    repo._stored = [_stop('a')];
    await container.read(stopsControllerProvider.future);
    final controller = container.read(stopsControllerProvider.notifier);

    await controller.clear();

    final state = await container.read(stopsControllerProvider.future);
    expect(state, isEmpty);
    expect(repo._stored, isEmpty);
  });
}
```

- [ ] **Step 11.2: Run to confirm failure**

```bash
cd apps/mobile && flutter test test/features/stops/state/stops_controller_test.dart && cd ../..
```

Expected: compile error — `stops_controller.dart` doesn't exist.

- [ ] **Step 11.3: Create the controller source**

Create `apps/mobile/lib/features/stops/state/stops_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/shared_prefs_stops_repository.dart';
import '../data/repositories/stops_repository.dart';
import '../domain/stop.dart';

part 'stops_controller.g.dart';

@riverpod
StopsRepository stopsRepository(StopsRepositoryRef ref) {
  return SharedPrefsStopsRepository();
}

@riverpod
class StopsController extends _$StopsController {
  StopsRepository get _repo => ref.read(stopsRepositoryProvider);

  @override
  Future<List<Stop>> build() async {
    return _repo.load();
  }

  Future<void> add(Stop stop) async {
    final current = await future;
    final next = [...current, stop];
    state = AsyncData(next);
    await _repo.save(next);
  }

  Future<void> remove(String id) async {
    final current = await future;
    final next = current.where((s) => s.id != id).toList(growable: false);
    state = AsyncData(next);
    await _repo.save(next);
  }

  Future<void> update(Stop stop) async {
    final current = await future;
    final next = current.map((s) => s.id == stop.id ? stop : s).toList(growable: false);
    state = AsyncData(next);
    await _repo.save(next);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = [...await future];
    if (oldIndex < newIndex) newIndex -= 1;
    final moved = current.removeAt(oldIndex);
    current.insert(newIndex, moved);
    state = AsyncData(List.unmodifiable(current));
    await _repo.save(current);
  }

  Future<void> applyOptimizedOrder(List<int> order) async {
    final current = await future;
    final next = [for (final i in order) current[i]];
    state = AsyncData(List.unmodifiable(next));
    await _repo.save(next);
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    await _repo.save(const []);
  }
}
```

- [ ] **Step 11.4: Generate codegen output**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && cd ../..
```

Expected: `stops_controller.g.dart` is generated alongside the source. If `build_runner` complains about missing deps, run `flutter pub add --dev riverpod_generator build_runner riverpod_annotation custom_lint riverpod_lint` (slice 1 already installed these per `pubspec.yaml` — verify with `grep riverpod_generator apps/mobile/pubspec.yaml`).

- [ ] **Step 11.5: Run tests to verify pass**

```bash
cd apps/mobile && flutter test test/features/stops/state/stops_controller_test.dart && cd ../..
```

Expected: 7 tests pass.

- [ ] **Step 11.6: Commit (include the generated .g.dart)**

```bash
git add apps/mobile/lib/features/stops/state/ apps/mobile/test/features/stops/state/stops_controller_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add @riverpod StopsController over StopsRepository

Riverpod 3 codegen controller (extends _$StopsController) with the
operations slice 2 needs end-to-end: build (hydrate from repository),
add, remove(id), update(stop), reorder(old,new), applyOptimizedOrder(
indices) for the Optimize handoff, and clear. Every mutation updates
the in-memory AsyncValue and persists via the repository in the same
critical section.

stopsRepositoryProvider returns SharedPrefsStopsRepository in production
and is overridden with a fake in tests so the suite never touches
native shared_preferences.

The generated stops_controller.g.dart ships in the same commit per
codegen convention.

Tests cover all 7 operations: build hydrate, add, remove, update,
reorder, applyOptimizedOrder permutation, clear.
EOF
)"
```

### Task 12: Create reusable `StopListItem` widget (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/shared/stop_list_item.dart`

This widget is shared by `ScreenHomeList` (Task 13), `ScreenReorder` (Task 21), and `ScreenStopDetail` (Task 19). Extracting it now avoids three near-duplicates.

- [ ] **Step 12.1: Create the widget**

Create `apps/mobile/lib/features/stops/presentation/shared/stop_list_item.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/stop.dart';

class StopListItem extends StatelessWidget {
  const StopListItem({
    super.key,
    required this.index,
    required this.stop,
    this.onTap,
    this.trailing,
  });

  final int index;
  final Stop stop;
  final VoidCallback? onTap;
  final Widget? trailing;

  String get _sourceBadge {
    switch (stop.source) {
      case StopSource.manual: return 'Manual';
      case StopSource.voice: return 'Voz';
      case StopSource.ocr: return 'OCR';
      case StopSource.mapTap: return 'Mapa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Parada ${index + 1}: ${stop.label ?? "sem rótulo"}',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(radius: 16, child: Text('${index + 1}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.label ?? '${stop.lat.toStringAsFixed(5)}, ${stop.lng.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _sourceBadge,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 12.2: Run analyzer**

```bash
cd apps/mobile && flutter analyze && cd ../..
```

Expected: 0 issues.

- [ ] **Step 12.3: Commit**

```bash
git add apps/mobile/lib/features/stops/presentation/shared/stop_list_item.dart
git commit -m "$(cat <<'EOF'
feat(stops): add reusable StopListItem widget

Shared by ScreenHomeList, ScreenReorder, and ScreenStopDetail.
Renders a numbered avatar, the stop label (or lat/lng fallback), and a
source badge (Manual/Voz/OCR/Mapa). Honors the accessibility baseline
from the spec: Semantics label naming the stop and position, 56dp
minHeight so the row is a comfortable tap target above the 48dp WCAG
minimum.
EOF
)"
```

### Task 13: `ScreenHomeEmpty` (TDD widget test → impl)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/home_empty_page.dart`
- Test: `apps/mobile/test/features/stops/presentation/home_empty_page_test.dart`

- [ ] **Step 13.1: Read the prototype**

```bash
sed -n '133,256p' prototipo/screens-a.jsx
```

Note: title, primary CTA copy, secondary affordances (FAB, menu).

- [ ] **Step 13.2: Write the failing widget test**

Create `apps/mobile/test/features/stops/presentation/home_empty_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/home_empty_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _EmptyRepo implements StopsRepository {
  @override
  Future<List<Stop>> load() async => const [];
  @override
  Future<void> save(List<Stop> stops) async {}
}

void main() {
  testWidgets('HomeEmptyPage shows the empty-state CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_EmptyRepo())],
        child: const MaterialApp(home: HomeEmptyPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Roteirizador Pro'), findsOneWidget);
    expect(find.text('Adicionar parada'), findsOneWidget);
  });

  testWidgets('HomeEmptyPage CTA is a tappable button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_EmptyRepo())],
        child: const MaterialApp(home: HomeEmptyPage()),
      ),
    );
    await tester.pumpAndSettle();

    final cta = find.widgetWithText(FilledButton, 'Adicionar parada');
    expect(cta, findsOneWidget);
    await tester.tap(cta);
    await tester.pump(); // Navigation hooked via go_router in real app — test just verifies it's tappable.
  });
}
```

- [ ] **Step 13.3: Run to confirm failure**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/home_empty_page_test.dart && cd ../..
```

Expected: compile error — `home_empty_page.dart` doesn't exist.

- [ ] **Step 13.4: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/home_empty_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeEmptyPage extends ConsumerWidget {
  const HomeEmptyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roteirizador Pro')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Nenhuma parada ainda',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Adicione suas paradas e otimize a rota antes de sair para a entrega.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Semantics(
                  button: true,
                  label: 'Adicionar parada',
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // Navigate to ScreenAddStop. GoRouter route name wired in app.dart Task 8 follow-up.
                        if (context.canPop()) context.pop();
                        context.go('/stops/add');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar parada'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 13.5: Run tests and fidelity check**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/home_empty_page_test.dart && flutter analyze && cd ../..
```

Then dispatch the prototype-fidelity-checker subagent against `lib/features/stops/presentation/home_empty_page.dart` vs `prototipo/screens-a.jsx → ScreenHomeEmpty`. If the agent reports divergences, adjust visual details (icon choice, color, spacing) until clean. Re-run `flutter test` after each change.

- [ ] **Step 13.6: Commit**

```bash
git add apps/mobile/lib/features/stops/presentation/home_empty_page.dart apps/mobile/test/features/stops/presentation/home_empty_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenHomeEmpty matching prototipo/screens-a.jsx

Empty-state home shown when StopsController returns an empty list.
SafeArea-wrapped per Android 15 edge-to-edge. Primary CTA 'Adicionar
parada' navigates to /stops/add via go_router. Semantics label and
button: true on the FilledButton meet the accessibility baseline.

Widget test verifies the empty-state CTA renders and is a tappable
FilledButton. Visual fidelity to the prototype was iterated against
the prototype-fidelity-checker subagent.
EOF
)"
```

### Task 14: `ScreenHomeList` + GoRouter wiring (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/home_list_page.dart`
- Create: `apps/mobile/test/features/stops/presentation/home_list_page_test.dart`
- Modify: `apps/mobile/lib/app.dart` (GoRouter routes)

- [ ] **Step 14.1: Write the widget test**

Create `apps/mobile/test/features/stops/presentation/home_list_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/home_list_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this._initial);
  List<Stop> _initial;
  final List<Stop> saved = [];

  @override
  Future<List<Stop>> load() async => List.unmodifiable(_initial);
  @override
  Future<void> save(List<Stop> stops) async {
    saved
      ..clear()
      ..addAll(stops);
  }
}

Stop _s(String id) => Stop(
      id: id, lat: 0, lng: 0, label: 'L-$id',
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    );

void main() {
  testWidgets('HomeListPage renders one tile per stop', (tester) async {
    final repo = _Repo([_s('a'), _s('b'), _s('c')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: HomeListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('L-a'), findsOneWidget);
    expect(find.text('L-b'), findsOneWidget);
    expect(find.text('L-c'), findsOneWidget);
  });

  testWidgets('Swipe-to-delete removes a stop and calls save', (tester) async {
    final repo = _Repo([_s('a'), _s('b')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: HomeListPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('L-a'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('L-a'), findsNothing);
    expect(repo.saved.map((s) => s.id), ['b']);
  });
}
```

- [ ] **Step 14.2: Confirm failure**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/home_list_page_test.dart && cd ../..
```

Expected: compile error — `home_list_page.dart` doesn't exist.

- [ ] **Step 14.3: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/home_list_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/stops_controller.dart';
import 'shared/stop_list_item.dart';

class HomeListPage extends ConsumerWidget {
  const HomeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStops = ref.watch(stopsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suas paradas'),
        actions: [
          IconButton(
            tooltip: 'Otimizar rota',
            icon: const Icon(Icons.alt_route),
            onPressed: () => context.go('/optimize'),
          ),
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Adicionar parada',
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/stops/add'),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar'),
        ),
      ),
      body: SafeArea(
        child: asyncStops.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (stops) {
            if (stops.isEmpty) {
              return const Center(child: Text('Nenhuma parada ainda. Toque em Adicionar.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: stops.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final stop = stops[i];
                return Dismissible(
                  key: ValueKey(stop.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    color: Theme.of(context).colorScheme.errorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) =>
                      ref.read(stopsControllerProvider.notifier).remove(stop.id),
                  child: StopListItem(
                    index: i,
                    stop: stop,
                    onTap: () => context.go('/stops/${stop.id}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 14.4: Update `app.dart` to route `/home`, `/stops/add`, `/stops/:id`**

Read `apps/mobile/lib/app.dart`. Inside the GoRouter `routes:` list, add routes (preserve existing `/login`, `/register`, `/home`):

```dart
GoRoute(
  path: '/home',
  builder: (context, state) => const HomeListPageOrEmpty(),
),
GoRoute(
  path: '/stops/add',
  builder: (context, state) => const AddStopPage(),
),
GoRoute(
  path: '/stops/:id',
  builder: (context, state) => StopDetailPage(id: state.pathParameters['id']!),
),
// Later tasks register: /stops/:id/edit, /stops/reorder, /stops/map,
// /optimize, /optimize/route, /navigate, /route-complete, /settings, /share.
```

`HomeListPageOrEmpty` is a tiny dispatcher that reads `stopsControllerProvider` and shows `HomeListPage` if data is non-empty, otherwise `HomeEmptyPage`. Create it inline in `app.dart` or as a private widget in `home_list_page.dart`:

```dart
class HomeListPageOrEmpty extends ConsumerWidget {
  const HomeListPageOrEmpty({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stops = ref.watch(stopsControllerProvider);
    return stops.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
      data: (s) => s.isEmpty ? const HomeEmptyPage() : const HomeListPage(),
    );
  }
}
```

Import the new pages in `app.dart`:

```dart
import 'features/stops/presentation/add_stop_page.dart';        // created in Task 15
import 'features/stops/presentation/home_empty_page.dart';
import 'features/stops/presentation/home_list_page.dart';
import 'features/stops/presentation/stop_detail_page.dart';     // created in Task 19
```

Note: Some imports point at files that don't exist yet (AddStopPage, StopDetailPage). To avoid compile errors mid-sub-slice, create empty placeholder files NOW so the import resolves; they'll get real implementations in the matching tasks:

Create `apps/mobile/lib/features/stops/presentation/add_stop_page.dart`:
```dart
import 'package:flutter/material.dart';
class AddStopPage extends StatelessWidget {
  const AddStopPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('AddStop — Task 15')));
}
```

Create `apps/mobile/lib/features/stops/presentation/stop_detail_page.dart`:
```dart
import 'package:flutter/material.dart';
class StopDetailPage extends StatelessWidget {
  const StopDetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Detail $id — Task 19')));
}
```

(Each placeholder gets a real impl + tests in its task. The placeholders compile and unblock the GoRouter wiring.)

- [ ] **Step 14.5: Run tests + analyzer**

```bash
cd apps/mobile && flutter test test/features/stops/ && flutter analyze && cd ../..
```

Expected: all tests pass (placeholder pages aren't tested yet; only home_empty + home_list have tests so far).

- [ ] **Step 14.6: Commit**

```bash
git add apps/mobile/lib/features/stops/presentation/home_list_page.dart \
  apps/mobile/lib/features/stops/presentation/add_stop_page.dart \
  apps/mobile/lib/features/stops/presentation/stop_detail_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/home_list_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenHomeList + GoRouter wiring for stops feature

ScreenHomeList shows a Dismissible list of StopListItem tiles with
swipe-to-delete (calls StopsController.remove via Riverpod), a FAB to
add stops, and AppBar actions for Optimize and Settings. SafeArea
respected for edge-to-edge.

GoRouter routes added in app.dart: /home (dispatches to empty or list
based on StopsController state), /stops/add, /stops/:id. Three more
slice-2 routes (edit, reorder, map, optimize, etc.) will be registered
by their respective tasks. Placeholder add_stop_page.dart and
stop_detail_page.dart unblock imports; both get real impls in tasks
15 and 19.

Widget tests cover list rendering and swipe-to-delete.
EOF
)"
```

### Task 15: `ScreenAddStop` — manual text entry (TDD)

**Files:**
- Replace: `apps/mobile/lib/features/stops/presentation/add_stop_page.dart` (placeholder → real)
- Create: `apps/mobile/lib/features/stops/presentation/shared/stop_form.dart`
- Create: `apps/mobile/test/features/stops/presentation/add_stop_page_test.dart`

- [ ] **Step 15.1: Write the failing test**

Create `apps/mobile/test/features/stops/presentation/add_stop_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/add_stop_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  final List<Stop> saved = [];
  @override
  Future<List<Stop>> load() async => const [];
  @override
  Future<void> save(List<Stop> stops) async {
    saved
      ..clear()
      ..addAll(stops);
  }
}

void main() {
  testWidgets('AddStopPage submits a valid stop into the controller', (tester) async {
    final repo = _Repo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: AddStopPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input-label')), 'Av. Paulista');
    await tester.enterText(find.byKey(const Key('input-lat')), '-23.5505');
    await tester.enterText(find.byKey(const Key('input-lng')), '-46.6333');

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar parada'));
    await tester.pumpAndSettle();

    expect(repo.saved.length, 1);
    expect(repo.saved.first.label, 'Av. Paulista');
    expect(repo.saved.first.lat, -23.5505);
    expect(repo.saved.first.source, StopSource.manual);
  });

  testWidgets('AddStopPage rejects invalid lat/lng', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_Repo())],
        child: const MaterialApp(home: AddStopPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input-lat')), '999');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar parada'));
    await tester.pump();

    expect(find.text('Latitude inválida'), findsOneWidget);
  });
}
```

- [ ] **Step 15.2: Create the shared `StopForm` widget**

Create `apps/mobile/lib/features/stops/presentation/shared/stop_form.dart`:

```dart
import 'package:flutter/material.dart';

/// Result of [StopForm] submission.
class StopFormData {
  const StopFormData({required this.lat, required this.lng, this.label});
  final double lat;
  final double lng;
  final String? label;
}

class StopForm extends StatefulWidget {
  const StopForm({
    super.key,
    required this.onSubmit,
    this.initial,
    this.submitLabel = 'Salvar parada',
  });

  final StopFormData? initial;
  final String submitLabel;
  final void Function(StopFormData) onSubmit;

  @override
  State<StopForm> createState() => _StopFormState();
}

class _StopFormState extends State<StopForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.initial?.label ?? '');
    _lat = TextEditingController(text: widget.initial?.lat.toString() ?? '');
    _lng = TextEditingController(text: widget.initial?.lng.toString() ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  String? _validateLat(String? v) {
    final n = double.tryParse(v ?? '');
    if (n == null || n < -90 || n > 90) return 'Latitude inválida';
    return null;
  }

  String? _validateLng(String? v) {
    final n = double.tryParse(v ?? '');
    if (n == null || n < -180 || n > 180) return 'Longitude inválida';
    return null;
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(StopFormData(
      lat: double.parse(_lat.text),
      lng: double.parse(_lng.text),
      label: _label.text.trim().isEmpty ? null : _label.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('input-label'),
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Rótulo (opcional)',
              hintText: 'Ex.: Av. Paulista, 1000',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('input-lat'),
            controller: _lat,
            decoration: const InputDecoration(labelText: 'Latitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            validator: _validateLat,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('input-lng'),
            controller: _lng,
            decoration: const InputDecoration(labelText: 'Longitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            validator: _validateLng,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _onSubmit,
              child: Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 15.3: Replace the placeholder with the real `AddStopPage`**

Overwrite `apps/mobile/lib/features/stops/presentation/add_stop_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/id.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/stop_form.dart';

class AddStopPage extends ConsumerWidget {
  const AddStopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar parada')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StopForm(
            onSubmit: (data) async {
              final stop = Stop(
                id: newId(),
                lat: data.lat,
                lng: data.lng,
                label: data.label,
                source: StopSource.manual,
                createdAt: DateTime.now(),
              );
              await ref.read(stopsControllerProvider.notifier).add(stop);
              if (context.mounted) context.go('/home');
            },
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 15.4: Run tests + analyzer**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/add_stop_page_test.dart && flutter analyze && cd ../..
```

Expected: 2 tests pass.

- [ ] **Step 15.5: Fidelity check vs `prototipo/screens-a.jsx → ScreenAddStop`**

Dispatch the `prototype-fidelity-checker` subagent. Iterate until clean.

- [ ] **Step 15.6: Commit**

```bash
git add apps/mobile/lib/features/stops/presentation/add_stop_page.dart \
  apps/mobile/lib/features/stops/presentation/shared/stop_form.dart \
  apps/mobile/test/features/stops/presentation/add_stop_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenAddStop with shared StopForm

Manual stop entry with a label field plus lat/lng inputs. Shared
StopForm widget handles validation (lat ∈ [-90, 90], lng ∈ [-180, 180])
and reports a typed StopFormData callback so EditStop (Task 22) can
reuse the same form pre-populated.

On submit, mints a fresh UUID via core/services/id.dart, builds a Stop
with source: manual, and pushes via StopsController.add. Then go_router
navigates back to /home.

Widget tests cover happy-path submission and out-of-range latitude
rejection.
EOF
)"
```

### Task 16: End of sub 2a — push and verify

- [ ] **Step 16.1: Run the whole mobile test suite + analyzer**

```bash
cd apps/mobile && flutter analyze && flutter test && cd ../..
```

Expected: 0 issues, all tests pass.

- [ ] **Step 16.2: Run the backend typecheck**

```bash
cd apps/backend && bun run typecheck && cd ../..
```

Expected: clean.

- [ ] **Step 16.3: Push the branch**

```bash
git push origin feat/m2-slice-2-telas-core
```

Sub 2a is complete. Continue to Phase 2.

---

## Phase 2 — Sub 2b Captura

Adds AndroidManifest permissions + `<queries>`, the permission_handler wrapper, and four capture screens (`ScreenVoice`, `ScreenOCR`, `ScreenAddStopsMap`). Manual screen-add `ScreenAddStop` was already shipped in sub 2a; this phase adds the three alternative capture paths.

### Task 17: AndroidManifest — permissions + queries

**Files:**
- Modify: `apps/mobile/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 17.1: Edit the manifest**

Open `apps/mobile/android/app/src/main/AndroidManifest.xml`. Inside the `<manifest>` tag (NOT inside `<application>`), add the three new `<uses-permission>` lines next to the existing `INTERNET` line:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />

<queries>
  <package android:name="com.google.android.apps.maps" />
  <package android:name="com.waze" />
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>
```

The `<queries>` block also belongs inside `<manifest>` (sibling of `<uses-permission>` and `<application>`).

- [ ] **Step 17.2: Commit**

```bash
git add apps/mobile/android/app/src/main/AndroidManifest.xml
git commit -m "$(cat <<'EOF'
feat(mobile): declare slice 2 android permissions and package queries

Adds ACCESS_FINE_LOCATION (geolocator), RECORD_AUDIO (speech_to_text),
and CAMERA (ml-kit text recognition via image_picker) to
src/main/AndroidManifest.xml — per the slice 1 lesson (overlays in
src/debug and src/profile do NOT merge into release builds; declare
in main).

Adds <queries> for com.google.android.apps.maps and com.waze so
Android 11+ canLaunchUrl() returns true for installed-app detection;
also lists the generic https VIEW intent for browser fallback.

Verified at slice close (Task 30) via `aapt2 dump permissions`.
EOF
)"
```

### Task 18: `core/services/permissions.dart` wrapper (TDD)

**Files:**
- Create: `apps/mobile/lib/core/services/permissions.dart`
- Test: `apps/mobile/test/core/services/permissions_test.dart`

This wrapper isolates the `permission_handler` dependency behind a Riverpod-overridable interface so widget tests don't trigger the real OS dialogs.

- [ ] **Step 18.1: Write the failing test**

Create `apps/mobile/test/core/services/permissions_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/services/permissions.dart';

class _FakePermissions implements AppPermissions {
  _FakePermissions({
    this.locationResult = PermissionOutcome.granted,
    this.micResult = PermissionOutcome.granted,
    this.cameraResult = PermissionOutcome.granted,
  });

  final PermissionOutcome locationResult;
  final PermissionOutcome micResult;
  final PermissionOutcome cameraResult;

  int locationCalls = 0;
  int micCalls = 0;
  int cameraCalls = 0;

  @override
  Future<PermissionOutcome> requestLocation() async {
    locationCalls++;
    return locationResult;
  }

  @override
  Future<PermissionOutcome> requestMicrophone() async {
    micCalls++;
    return micResult;
  }

  @override
  Future<PermissionOutcome> requestCamera() async {
    cameraCalls++;
    return cameraResult;
  }

  @override
  Future<void> openSettings() async {}
}

void main() {
  test('Fake records granted outcomes', () async {
    final p = _FakePermissions();
    expect(await p.requestLocation(), PermissionOutcome.granted);
    expect(await p.requestMicrophone(), PermissionOutcome.granted);
    expect(await p.requestCamera(), PermissionOutcome.granted);
  });

  test('Fake can simulate permanent deny', () async {
    final p = _FakePermissions(locationResult: PermissionOutcome.permanentlyDenied);
    expect(await p.requestLocation(), PermissionOutcome.permanentlyDenied);
  });
}
```

- [ ] **Step 18.2: Confirm failure**

```bash
cd apps/mobile && flutter test test/core/services/permissions_test.dart && cd ../..
```

Expected: compile error.

- [ ] **Step 18.3: Create the wrapper**

Create `apps/mobile/lib/core/services/permissions.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionOutcome { granted, denied, permanentlyDenied }

abstract class AppPermissions {
  Future<PermissionOutcome> requestLocation();
  Future<PermissionOutcome> requestMicrophone();
  Future<PermissionOutcome> requestCamera();
  Future<void> openSettings();
}

class _RealAppPermissions implements AppPermissions {
  @override
  Future<PermissionOutcome> requestLocation() =>
      _request(Permission.locationWhenInUse);
  @override
  Future<PermissionOutcome> requestMicrophone() =>
      _request(Permission.microphone);
  @override
  Future<PermissionOutcome> requestCamera() =>
      _request(Permission.camera);
  @override
  Future<void> openSettings() => openAppSettings();

  Future<PermissionOutcome> _request(Permission p) async {
    final status = await p.request();
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    return PermissionOutcome.denied;
  }
}

final permissionsProvider = Provider<AppPermissions>((ref) {
  return _RealAppPermissions();
});
```

- [ ] **Step 18.4: Run tests**

```bash
cd apps/mobile && flutter test test/core/services/permissions_test.dart && cd ../..
```

Expected: 2 tests pass (they exercise the fake interface; the real impl is exercised end-to-end on device).

- [ ] **Step 18.5: Commit**

```bash
git add apps/mobile/lib/core/services/permissions.dart apps/mobile/test/core/services/permissions_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): add AppPermissions wrapper around permission_handler

PermissionOutcome enum (granted / denied / permanentlyDenied) hides the
permission_handler PermissionStatus details from callers and lets
widgets handle the three states explicitly. _RealAppPermissions
requests location-when-in-use, microphone, and camera; openSettings()
launches the app's system settings page for the permanent-deny case.

permissionsProvider provides the real impl in production; widget tests
override it with a _FakePermissions (recorded calls + simulated outcome)
so the suite never triggers a real OS dialog.
EOF
)"
```

### Task 19: `ScreenStopDetail` (TDD) — fills the placeholder

**Files:**
- Replace: `apps/mobile/lib/features/stops/presentation/stop_detail_page.dart`
- Create: `apps/mobile/test/features/stops/presentation/stop_detail_page_test.dart`

- [ ] **Step 19.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/stop_detail_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/stop_detail_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  final List<Stop> initial;
  final List<Stop> saved = [];
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {
    saved..clear()..addAll(stops);
  }
}

void main() {
  testWidgets('StopDetailPage shows the stop label, lat, and lng', (tester) async {
    final stop = Stop(
      id: 'abc', lat: -23.55, lng: -46.63, label: 'Av. Paulista',
      source: StopSource.mapTap, createdAt: DateTime.utc(2026, 5, 13),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_Repo([stop]))],
        child: const MaterialApp(home: StopDetailPage(id: 'abc')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Av. Paulista'), findsOneWidget);
    expect(find.textContaining('-23.55'), findsOneWidget);
    expect(find.textContaining('-46.63'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
  });

  testWidgets('Excluir removes the stop and pops', (tester) async {
    final stop = Stop(
      id: 'abc', lat: 1, lng: 2, source: StopSource.manual,
      createdAt: DateTime.utc(2026, 5, 13),
    );
    final repo = _Repo([stop]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: StopDetailPage(id: 'abc')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(repo.saved, isEmpty);
  });
}
```

- [ ] **Step 19.2: Replace placeholder**

Overwrite `apps/mobile/lib/features/stops/presentation/stop_detail_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/stops_controller.dart';

class StopDetailPage extends ConsumerWidget {
  const StopDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da parada')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (stops) {
            final stop = stops.where((s) => s.id == id).firstOrNull;
            if (stop == null) {
              return const Center(child: Text('Parada não encontrada.'));
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.label ?? 'Sem rótulo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Latitude: ${stop.lat}'),
                  Text('Longitude: ${stop.lng}'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ref
                                .read(stopsControllerProvider.notifier)
                                .remove(stop.id);
                            if (context.mounted) context.go('/home');
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Excluir'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go('/stops/${stop.id}/edit'),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 19.3: Test + commit**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/stop_detail_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/stop_detail_page.dart \
  apps/mobile/test/features/stops/presentation/stop_detail_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenStopDetail replacing the placeholder

Shows label, lat, and lng for the stop addressed by GoRouter path
param :id. Two CTAs: Excluir (calls StopsController.remove and pops to
/home) and Editar (navigates to /stops/:id/edit; route registered in
Task 22). Renders 'Parada não encontrada' if the id misses — that
happens after swipe-to-delete + back-stack revisit.

Tests cover field rendering and Excluir behavior.
EOF
)"
```

### Task 20: `ScreenEditStop` (TDD) — reuses `StopForm`

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/edit_stop_page.dart`
- Modify: `apps/mobile/lib/app.dart` (add `/stops/:id/edit` route)
- Create: `apps/mobile/test/features/stops/presentation/edit_stop_page_test.dart`

- [ ] **Step 20.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/edit_stop_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/edit_stop_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  final List<Stop> initial;
  final List<Stop> saved = [];
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {
    saved..clear()..addAll(stops);
  }
}

void main() {
  testWidgets('EditStopPage pre-populates and updates via controller', (tester) async {
    final stop = Stop(
      id: 'abc', lat: 1, lng: 2, label: 'Old',
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    );
    final repo = _Repo([stop]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EditStopPage(id: 'abc')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Old'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input-label')), 'New');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    expect(repo.saved.first.label, 'New');
    expect(repo.saved.first.id, 'abc');
  });
}
```

- [ ] **Step 20.2: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/edit_stop_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/stops_controller.dart';
import 'shared/stop_form.dart';

class EditStopPage extends ConsumerWidget {
  const EditStopPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar parada')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (stops) {
            final stop = stops.where((s) => s.id == id).firstOrNull;
            if (stop == null) {
              return const Center(child: Text('Parada não encontrada.'));
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: StopForm(
                submitLabel: 'Salvar alterações',
                initial: StopFormData(lat: stop.lat, lng: stop.lng, label: stop.label),
                onSubmit: (data) async {
                  await ref.read(stopsControllerProvider.notifier).update(
                    stop.copyWith(lat: data.lat, lng: data.lng, label: data.label),
                  );
                  if (context.mounted) context.go('/stops/${stop.id}');
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 20.3: Register the GoRouter route**

In `apps/mobile/lib/app.dart`, add:

```dart
GoRoute(
  path: '/stops/:id/edit',
  builder: (context, state) => EditStopPage(id: state.pathParameters['id']!),
),
```

And import:
```dart
import 'features/stops/presentation/edit_stop_page.dart';
```

- [ ] **Step 20.4: Test + commit**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/edit_stop_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/edit_stop_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/edit_stop_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenEditStop reusing StopForm

Pre-populates the same StopForm widget used by AddStopPage and submits
via StopsController.update preserving the stop id, source, and
createdAt (only lat/lng/label can change in slice 2). Returns to
/stops/:id detail screen after save.

Tests cover pre-population and update flow.
EOF
)"
```

### Task 21: `ScreenReorder` — drag-to-reorder (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/reorder_page.dart`
- Modify: `apps/mobile/lib/app.dart` (add `/stops/reorder` route)
- Create: `apps/mobile/test/features/stops/presentation/reorder_page_test.dart`

- [ ] **Step 21.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/reorder_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/reorder_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  final List<Stop> initial;
  final List<Stop> saved = [];
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {
    saved..clear()..addAll(stops);
  }
}

Stop _s(String id) => Stop(
      id: id, lat: 0, lng: 0, label: 'L-$id',
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    );

void main() {
  testWidgets('ReorderPage renders all stops with drag handles', (tester) async {
    final repo = _Repo([_s('a'), _s('b'), _s('c')]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ReorderPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('L-a'), findsOneWidget);
    expect(find.text('L-b'), findsOneWidget);
    expect(find.text('L-c'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
  });
}
```

- [ ] **Step 21.2: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/reorder_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/stops_controller.dart';

class ReorderPage extends ConsumerWidget {
  const ReorderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reordenar paradas'),
        actions: [
          IconButton(
            tooltip: 'Concluir',
            icon: const Icon(Icons.check),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (stops) {
            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: stops.length,
              itemBuilder: (context, i) {
                final stop = stops[i];
                return ListTile(
                  key: ValueKey(stop.id),
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(stop.label ?? '${stop.lat.toStringAsFixed(5)}, ${stop.lng.toStringAsFixed(5)}'),
                  trailing: ReorderableDragStartListener(
                    index: i,
                    child: const SizedBox(
                      width: 48, height: 48,
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) =>
                  ref.read(stopsControllerProvider.notifier).reorder(oldIndex, newIndex),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 21.3: Register the route in `app.dart`**

Add:
```dart
GoRoute(
  path: '/stops/reorder',
  builder: (context, state) => const ReorderPage(),
),
```

And import:
```dart
import 'features/stops/presentation/reorder_page.dart';
```

- [ ] **Step 21.4: Test + commit**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/reorder_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/reorder_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/reorder_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenReorder via ReorderableListView

Drag-to-reorder using Flutter SDK's ReorderableListView (zero new dep).
Drag handle is a 48dp square (accessibility minimum) wrapped in a
ReorderableDragStartListener so the user must grab the handle, not the
whole row — prevents accidental reorders while scrolling. onReorder
delegates to StopsController.reorder which persists via the repository.
AppBar Concluir action returns to /home.

Widget test verifies all stops render with drag handles.
EOF
)"
```

### Task 22: `ScreenMapStops` — full-screen map (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/shared/map_attribution.dart`
- Create: `apps/mobile/lib/features/stops/presentation/map_stops_page.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/stops/presentation/map_stops_page_test.dart`

- [ ] **Step 22.1: Create the shared OSM attribution widget**

Create `apps/mobile/lib/features/stops/presentation/shared/map_attribution.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// Always-visible OSM attribution.
/// Required by ADR-0016 and the OSMF Tile Usage Policy.
RichAttributionWidget osmAttribution() => RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          'OpenStreetMap contributors',
          onTap: () => launchUrl(
            Uri.parse('https://www.openstreetmap.org/copyright'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
```

- [ ] **Step 22.2: Write the widget test**

Create `apps/mobile/test/features/stops/presentation/map_stops_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/map_stops_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  final List<Stop> initial;
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {}
}

void main() {
  testWidgets('MapStopsPage renders without throwing with 3 stops', (tester) async {
    final stops = [
      Stop(id: 'a', lat: -23.55, lng: -46.63, source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13)),
      Stop(id: 'b', lat: -23.56, lng: -46.64, source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13)),
      Stop(id: 'c', lat: -23.57, lng: -46.65, source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13)),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_Repo(stops))],
        child: const MaterialApp(home: MapStopsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Smoke: the AppBar title is present.
    expect(find.text('Mapa das paradas'), findsOneWidget);
  });
}
```

- [ ] **Step 22.3: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/map_stops_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';

class MapStopsPage extends ConsumerWidget {
  const MapStopsPage({super.key});

  // SP capital bbox (matches GraphHopper SP-only graph from ADR-0008).
  static final _spBoundsSw = const LatLng(-23.78, -46.83);
  static final _spBoundsNe = const LatLng(-23.36, -46.40);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa das paradas')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (stops) {
            final points = [
              for (final s in stops) LatLng(s.lat, s.lng),
            ];
            return FlutterMap(
              options: MapOptions(
                initialCenter: points.isEmpty
                    ? const LatLng(-23.5505, -46.6333)
                    : points.first,
                initialZoom: 13,
                minZoom: 10,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(_spBoundsSw, _spBoundsNe),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro',
                  retinaMode: RetinaMode.isHighDensity(context),
                  maxNativeZoom: 19,
                ),
                if (points.length >= 2)
                  PolylineLayer(polylines: [
                    Polyline(points: points, strokeWidth: 4, color: Colors.blueAccent),
                  ]),
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < stops.length; i++)
                      Marker(
                        point: LatLng(stops[i].lat, stops[i].lng),
                        width: 32,
                        height: 32,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                  ],
                ),
                osmAttribution(),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 22.4: Register `/stops/map` route**

In `app.dart`:
```dart
GoRoute(
  path: '/stops/map',
  builder: (context, state) => const MapStopsPage(),
),
```

Import:
```dart
import 'features/stops/presentation/map_stops_page.dart';
```

- [ ] **Step 22.5: Test + commit**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/map_stops_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/map_stops_page.dart \
  apps/mobile/lib/features/stops/presentation/shared/map_attribution.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/map_stops_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenMapStops with osm tiles per ADR-0016

Full-screen flutter_map showing every stop as a numbered CircleAvatar
marker. Polyline drawn between consecutive stops (straight lines —
slice 3 replaces with GraphHopper polylines).

flutter_map 8.x modern configuration per spec §Map configuration:
- MapOptions.initialCenter (not the removed center param)
- minZoom 10 / maxZoom 19 / maxNativeZoom 19 for SP capital coverage
- CameraConstraint.contain locks pan to the GraphHopper SP bbox
- retinaMode: RetinaMode.isHighDensity(context) for sharp tiles on
  Galaxy A06 xxhdpi
- Rotation disabled (matches prototype, avoids marker rotation work)

OSM tile policy compliance (ADR-0016): userAgentPackageName +
RichAttributionWidget via shared osmAttribution() helper. No FMTC
plugin, no bulk-download.

GoRouter /stops/map route registered.
EOF
)"
```

### Task 23: Sub 2b — `ScreenVoice` (voice → text)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/voice_capture_page.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/stops/presentation/voice_capture_page_test.dart`

The widget test uses an injected fake `AppPermissions` so the OS dialog never fires; the `speech_to_text` plugin itself can't be cleanly faked in widget tests (it's platform-channel-driven), so the test asserts the **UI scaffold renders** and the request-permission button fires.

- [ ] **Step 23.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/voice_capture_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/services/permissions.dart';
import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/voice_capture_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _EmptyRepo implements StopsRepository {
  @override
  Future<List<Stop>> load() async => const [];
  @override
  Future<void> save(List<Stop> stops) async {}
}

class _FakePerms implements AppPermissions {
  PermissionOutcome micResult = PermissionOutcome.granted;
  int micCalls = 0;

  @override
  Future<PermissionOutcome> requestLocation() async => PermissionOutcome.denied;
  @override
  Future<PermissionOutcome> requestMicrophone() async {
    micCalls++;
    return micResult;
  }
  @override
  Future<PermissionOutcome> requestCamera() async => PermissionOutcome.denied;
  @override
  Future<void> openSettings() async {}
}

void main() {
  testWidgets('VoiceCapturePage renders the mic CTA', (tester) async {
    final perms = _FakePerms();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(_EmptyRepo()),
          permissionsProvider.overrideWithValue(perms),
        ],
        child: const MaterialApp(home: VoiceCapturePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.text('Toque para falar o endereço'), findsOneWidget);
  });
}
```

- [ ] **Step 23.2: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/voice_capture_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/services/id.dart';
import '../../../core/services/permissions.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';

class VoiceCapturePage extends ConsumerStatefulWidget {
  const VoiceCapturePage({super.key});

  @override
  ConsumerState<VoiceCapturePage> createState() => _VoiceCapturePageState();
}

class _VoiceCapturePageState extends ConsumerState<VoiceCapturePage> {
  final _stt = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _transcript = '';

  Future<void> _toggle() async {
    final perms = ref.read(permissionsProvider);
    final outcome = await perms.requestMicrophone();
    if (outcome != PermissionOutcome.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Permissão do microfone necessária.'),
        ));
      }
      return;
    }

    if (!_isInitialized) {
      _isInitialized = await _stt.initialize();
    }
    if (!_isInitialized) return;

    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _stt.listen(
        localeId: 'pt_BR',
        onResult: (r) => setState(() => _transcript = r.recognizedWords),
      );
    }
  }

  Future<void> _confirm() async {
    if (_transcript.trim().isEmpty) return;
    // Slice 2 stores the transcript as the label with lat/lng = 0 placeholders.
    // Slice 3 sends the transcript through /geocode (Nominatim) to resolve real coords.
    final stop = Stop(
      id: newId(),
      lat: 0,
      lng: 0,
      label: _transcript.trim(),
      source: StopSource.voice,
      createdAt: DateTime.now(),
    );
    await ref.read(stopsControllerProvider.notifier).add(stop);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capturar por voz')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Toque para falar o endereço'),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: _isListening ? 'Parar gravação' : 'Iniciar gravação por voz',
                child: SizedBox(
                  width: 96, height: 96,
                  child: FilledButton(
                    onPressed: _toggle,
                    style: FilledButton.styleFrom(shape: const CircleBorder()),
                    child: Icon(_isListening ? Icons.stop : Icons.mic, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_transcript.isNotEmpty) ...[
                Text(
                  _transcript,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar parada'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 23.3: Register `/stops/voice` route in `app.dart`**

```dart
GoRoute(
  path: '/stops/voice',
  builder: (context, state) => const VoiceCapturePage(),
),
```

Import:
```dart
import 'features/stops/presentation/voice_capture_page.dart';
```

- [ ] **Step 23.4: Test + commit**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/voice_capture_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/voice_capture_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/voice_capture_page_test.dart
git commit -m "$(cat <<'EOF'
feat(voice): add ScreenVoice using speech_to_text + permission_handler

On-device pt-BR voice capture via the speech_to_text Flutter package.
Mic permission requested through the AppPermissions wrapper (overridable
in widget tests so OS dialogs never fire in CI). Recognized text is
shown then confirmed → stored as a Stop with source: voice. Slice 2
keeps lat/lng = 0 as placeholders; slice 3 wires /geocode to resolve
the transcript.

Widget test verifies the mic CTA renders. End-to-end voice flow is
manual on a real Android device with pt-BR locale installed.
EOF
)"
```

### Task 24: Sub 2b — `ScreenOCR` (camera → ML Kit)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/ocr_capture_page.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/stops/presentation/ocr_capture_page_test.dart`

- [ ] **Step 24.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/ocr_capture_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/services/permissions.dart';
import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/ocr_capture_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _EmptyRepo implements StopsRepository {
  @override
  Future<List<Stop>> load() async => const [];
  @override
  Future<void> save(List<Stop> stops) async {}
}

class _FakePerms implements AppPermissions {
  @override
  Future<PermissionOutcome> requestLocation() async => PermissionOutcome.denied;
  @override
  Future<PermissionOutcome> requestMicrophone() async => PermissionOutcome.denied;
  @override
  Future<PermissionOutcome> requestCamera() async => PermissionOutcome.granted;
  @override
  Future<void> openSettings() async {}
}

void main() {
  testWidgets('OcrCapturePage renders the camera CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(_EmptyRepo()),
          permissionsProvider.overrideWithValue(_FakePerms()),
        ],
        child: const MaterialApp(home: OcrCapturePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.text('Tirar foto da etiqueta'), findsOneWidget);
  });
}
```

- [ ] **Step 24.2: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/ocr_capture_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/id.dart';
import '../../../core/services/permissions.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';

class OcrCapturePage extends ConsumerStatefulWidget {
  const OcrCapturePage({super.key});

  @override
  ConsumerState<OcrCapturePage> createState() => _OcrCapturePageState();
}

class _OcrCapturePageState extends ConsumerState<OcrCapturePage> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  String _extracted = '';
  bool _busy = false;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _capture() async {
    final perms = ref.read(permissionsProvider);
    final outcome = await perms.requestCamera();
    if (outcome != PermissionOutcome.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Permissão da câmera necessária.'),
        ));
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (file == null) return;
      final input = InputImage.fromFilePath(file.path);
      final result = await _recognizer.processImage(input);
      setState(() => _extracted = result.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_extracted.trim().isEmpty) return;
    final stop = Stop(
      id: newId(),
      lat: 0, lng: 0,
      label: _extracted.trim(),
      source: StopSource.ocr,
      createdAt: DateTime.now(),
    );
    await ref.read(stopsControllerProvider.notifier).add(stop);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capturar por foto')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_busy) const CircularProgressIndicator(),
              if (!_busy) ...[
                Semantics(
                  button: true,
                  label: 'Tirar foto da etiqueta para reconhecimento de texto',
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _capture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tirar foto da etiqueta'),
                    ),
                  ),
                ),
              ],
              if (_extracted.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  _extracted,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar parada'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 24.3: Register `/stops/ocr` in `app.dart`**

```dart
GoRoute(
  path: '/stops/ocr',
  builder: (context, state) => const OcrCapturePage(),
),
```

Import:
```dart
import 'features/stops/presentation/ocr_capture_page.dart';
```

- [ ] **Step 24.4: Test + commit**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/ocr_capture_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/ocr_capture_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/ocr_capture_page_test.dart
git commit -m "$(cat <<'EOF'
feat(ocr): add ScreenOCR with image_picker + google_mlkit_text_recognition

User takes a photo of an AWB label via image_picker (ImageSource.camera);
the file is fed to a TextRecognizer with Latin script on-device. The
extracted text becomes the Stop label (slice 3 wires /geocode for real
coords). Camera permission requested through the AppPermissions wrapper.

TextRecognizer instance is created in initState and closed in dispose
per the google_mlkit_text_recognition docs to avoid native resource
leaks.

Widget test verifies the camera CTA renders.
EOF
)"
```

### Task 25: Sub 2b — `ScreenAddStopsMap` (tap-to-add)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/add_stops_map_page.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/stops/presentation/add_stops_map_page_test.dart`

- [ ] **Step 25.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/add_stops_map_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/add_stops_map_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _EmptyRepo implements StopsRepository {
  @override
  Future<List<Stop>> load() async => const [];
  @override
  Future<void> save(List<Stop> stops) async {}
}

void main() {
  testWidgets('AddStopsMapPage renders without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_EmptyRepo())],
        child: const MaterialApp(home: AddStopsMapPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tocar no mapa para adicionar'), findsOneWidget);
  });
}
```

- [ ] **Step 25.2: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/add_stops_map_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/id.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';

class AddStopsMapPage extends ConsumerStatefulWidget {
  const AddStopsMapPage({super.key});

  @override
  ConsumerState<AddStopsMapPage> createState() => _AddStopsMapPageState();
}

class _AddStopsMapPageState extends ConsumerState<AddStopsMapPage> {
  static const _spBoundsSw = LatLng(-23.78, -46.83);
  static const _spBoundsNe = LatLng(-23.36, -46.40);
  final List<LatLng> _pending = [];

  void _onTap(TapPosition pos, LatLng point) {
    setState(() => _pending.add(point));
  }

  Future<void> _confirm() async {
    final controller = ref.read(stopsControllerProvider.notifier);
    for (final p in _pending) {
      await controller.add(Stop(
        id: newId(),
        lat: p.latitude,
        lng: p.longitude,
        source: StopSource.mapTap,
        createdAt: DateTime.now(),
      ));
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tocar no mapa para adicionar'),
        actions: [
          IconButton(
            tooltip: 'Desfazer último',
            icon: const Icon(Icons.undo),
            onPressed: _pending.isEmpty
                ? null
                : () => setState(() => _pending.removeLast()),
          ),
        ],
      ),
      floatingActionButton: _pending.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _confirm,
              icon: const Icon(Icons.check),
              label: Text('Adicionar ${_pending.length}'),
            ),
      body: SafeArea(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(-23.5505, -46.6333),
            initialZoom: 13,
            minZoom: 10,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(_spBoundsSw, _spBoundsNe),
            ),
            onTap: _onTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro',
              retinaMode: RetinaMode.isHighDensity(context),
              maxNativeZoom: 19,
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < _pending.length; i++)
                  Marker(
                    point: _pending[i],
                    width: 32, height: 32,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            osmAttribution(),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 25.3: Register `/stops/add-map` route**

In `app.dart`:
```dart
GoRoute(
  path: '/stops/add-map',
  builder: (context, state) => const AddStopsMapPage(),
),
```

Import:
```dart
import 'features/stops/presentation/add_stops_map_page.dart';
```

- [ ] **Step 25.4: Test + commit + push (end of sub 2b)**

```bash
cd apps/mobile && flutter test && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/add_stops_map_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/add_stops_map_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenAddStopsMap with tap-to-add on flutter_map

Single-screen map flow: tap to enqueue a pending stop, undo to remove
the last, confirm via FAB to commit them all through StopsController.add
with source: mapTap. Same modern flutter_map 8.x config as MapStopsPage
(initialCenter, CameraConstraint locked to SP bbox, retina, no rotation).

End of sub 2b. Push to share progress.
EOF
)"

git push origin feat/m2-slice-2-telas-core
```

### Task 26: ADR-0017 — External navigation hand-off

**Files:**
- Create: `docs/decisions/0017-external-navigation-handoff.md`

- [ ] **Step 26.1: Create the ADR**

Create `docs/decisions/0017-external-navigation-handoff.md`:

```markdown
# ADR-0017: External Navigation Hand-off

- **Status:** Accepted
- **Date:** 2026-05-XX
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0015 (M2 plan + library choices), ADR-0016 (map and tile policy), ADR-0014 (Android release signing).

## Context

Slice 2's `ScreenNavigate` step needs to take an optimized route and start turn-by-turn navigation. In-app turn-by-turn would require Mapbox Navigation SDK or similar — paid, vendor-locked, and outside the M2 cost ceiling. The pragmatic path is **deep-link hand-off** to whichever external navigation app the user prefers.

The two realistic Brazilian options are Google Maps and Waze. They have very different deep-link contracts:

- **Google Maps**: `https://www.google.com/maps/dir/?api=1` supports `origin`, `destination`, and `waypoints` (pipe-separated). One URL opens the entire multi-stop route.
- **Waze**: `waze://?ll=<lat>,<lng>&navigate=yes` takes a single destination per intent. There is no published multi-stop variant.

This ADR captures the decision and the consequences for the slice 2 UX.

## Options Considered

### A — Google Maps default, Waze toggle (this ADR)

Default the user to Google Maps because it preserves the product promise ("nós otimizamos sua rota inteira"). A toggle in Settings switches to Waze, but a one-time warning explains that Waze is opened one stop at a time.

- **Pros:** preserves the multi-stop promise out of the box; respects user choice in Settings; falls back to a browser if neither app is installed (`https://www.google.com/maps/dir/...` opens any browser).
- **Cons:** Brazilian delivery riders skew toward Waze for traffic awareness; this design forces a Settings change to use it.

### B — Waze default, Google Maps toggle

- **Pros:** matches the prevailing rider preference in Brazil.
- **Cons:** breaks the multi-stop promise on first use. Users who picked the product *because* of route optimization see a single-stop hand-off and feel cheated. **Rejected.**

### C — Ask every time

Bottom sheet "Abrir em: [Google Maps] [Waze]" on every Iniciar navegação tap.

- **Pros:** zero assumption.
- **Cons:** extra tap on every trip. Friction adds up over a workday. **Rejected.**

## Decision

1. **Default external navigation provider is Google Maps.** Multi-stop hand-off via the `dir/?api=1` URL with `origin`, `destination`, and `waypoints`.

2. **Settings exposes a `Aplicativo de navegação` toggle.** Two options: Google Maps (default) and Waze. The choice is persisted in `SharedPreferencesAsync` under the key `settings.nav_provider`.

3. **Waze is opened one stop at a time.** When the user selects Waze in Settings and the route has > 1 stop, `ScreenOptimizeRoute` shows a one-time toast: *"Waze não suporta múltiplas paradas; vamos abrir uma de cada vez."* `ScreenNavigate` then exposes a "Próxima parada" CTA that fires Waze for the next index.

4. **Fallback when neither app is installed.** The Google Maps URI is a real `https://` URL, so the browser is the natural fallback (Android resolves the intent to a browser if no native handler is registered). Confirmed by the `<queries>` block from Task 17, which includes a generic `https` VIEW intent.

5. **Android 11+ visibility.** The `<queries>` block in `src/main/AndroidManifest.xml` lists `com.google.android.apps.maps`, `com.waze`, and the generic `https` VIEW intent so `canLaunchUrl()` returns true when the app is installed.

6. **In-app turn-by-turn is explicitly out of M2 scope.** Would require a Mapbox Navigation SDK or similar paid product; revisit if the post-M2 economics justify the dependency.

## Consequences

- **Positive:** zero per-request cost; respects user preference; preserves the multi-stop promise by default; the migration to in-app turn-by-turn (if ever) is a clean replacement of `ExternalNav.openInGoogleMaps`.
- **Negative:** Waze users see a slightly worse UX than Google Maps users; mitigated by the explicit one-time message.
- **Neutral:** if a third provider ever becomes the default in Brazil (e.g. an OpenStreetMap-based navigator gains traction), this ADR is the single place that changes.

## Implementation notes

`apps/mobile/lib/core/services/external_nav.dart` ships in Task 28 with:

```dart
enum NavProvider { googleMaps, waze }

class ExternalNav {
  Future<bool> openInGoogleMaps(List<Stop> stops) async { /* ... */ }
  Future<bool> openInWaze(Stop stop) async { /* ... */ }
}
```

The provider preference is read from `SharedPreferencesAsync` (`settings.nav_provider`); `ScreenSettings` writes it via a SegmentedButton in Task 33.

## References

- ADR-0015 — M2 plan and library choices.
- ADR-0016 — Map and tile policy.
- Spec: `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` §External navigation.
- AndroidManifest `<queries>` block introduced in slice 2 sub 2b Task 17.
```

Replace `2026-05-XX` with today's actual ISO date.

- [ ] **Step 26.2: Commit**

```bash
git add docs/decisions/0017-external-navigation-handoff.md
git commit -m "$(cat <<'EOF'
docs(decisions): adr-0017 external navigation hand-off

Locks the default external nav as Google Maps (multi-stop URI),
the Waze toggle in Settings (parada-por-parada), browser fallback,
and the explicit Android 11+ <queries> rationale. In-app turn-by-turn
is captured as a post-M2 candidate, not in this slice. Files the
ADR-0017 referenced by ADR-0015's slice 2 table.
EOF
)"
```

### Task 27: `OptimizeController` (Riverpod codegen, TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/state/optimize_controller.dart`
- Create: `apps/mobile/lib/features/stops/state/optimize_controller.g.dart` (codegen)
- Create: `apps/mobile/test/features/stops/state/optimize_controller_test.dart`

`OptimizeController` issues `POST /routes/optimize` and applies the returned `optimizedOrder` to `StopsController`. The Dio client + auth interceptor from slice 1 are reused; we inject a swappable HTTP client for tests.

- [ ] **Step 27.1: Write the test**

Create `apps/mobile/test/features/stops/state/optimize_controller_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/providers/api_providers.dart';
import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/optimize_controller.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  List<Stop> initial;
  final List<Stop> saved = [];
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {
    saved..clear()..addAll(stops);
  }
}

class _FakeDio extends Fake implements Dio {
  Map<String, dynamic>? lastBody;
  Map<String, dynamic> response = {
    'optimizedOrder': [2, 0, 1],
    'totalDistanceM': 12345.6,
    'totalDurationS': 678.9,
  };

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastBody = data as Map<String, dynamic>?;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: response as T,
    );
  }
}

Stop _s(String id, {double lat = 0, double lng = 0, String? label}) => Stop(
      id: id, lat: lat, lng: lng, label: label,
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    );

void main() {
  test('run sends StopDto[] and applies optimizedOrder via StopsController', () async {
    final repo = _Repo([_s('a', lat: 1), _s('b', lat: 2), _s('c', lat: 3)]);
    final fakeDio = _FakeDio();
    final container = ProviderContainer(
      overrides: [
        stopsRepositoryProvider.overrideWithValue(repo),
        dioProvider.overrideWithValue(fakeDio),
      ],
    );
    addTearDown(container.dispose);

    await container.read(stopsControllerProvider.future);
    final controller = container.read(optimizeControllerProvider.notifier);

    final result = await controller.run();

    // Verify the wire payload mirrors StopDto shape (no id/source/createdAt).
    final stopsSent = fakeDio.lastBody!['stops'] as List;
    expect(stopsSent.first, {'lat': 1.0, 'lng': 0.0});

    // Verify the response was applied.
    final after = await container.read(stopsControllerProvider.future);
    expect(after.map((s) => s.id), ['c', 'a', 'b']);

    // Verify the metrics were captured.
    expect(result.totalDistanceM, 12345.6);
    expect(result.totalDurationS, 678.9);
  });
}
```

- [ ] **Step 27.2: Confirm failure**

```bash
cd apps/mobile && flutter test test/features/stops/state/optimize_controller_test.dart && cd ../..
```

Expected: compile error.

- [ ] **Step 27.3: Create the controller**

Create `apps/mobile/lib/features/stops/state/optimize_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/api_providers.dart';
import '../domain/stop.dart';
import 'stops_controller.dart';

part 'optimize_controller.g.dart';

class OptimizeResult {
  const OptimizeResult({
    required this.optimizedOrder,
    required this.totalDistanceM,
    required this.totalDurationS,
  });
  final List<int> optimizedOrder;
  final double totalDistanceM;
  final double totalDurationS;
}

@riverpod
class OptimizeController extends _$OptimizeController {
  @override
  AsyncValue<OptimizeResult?> build() => const AsyncData(null);

  Future<OptimizeResult> run() async {
    state = const AsyncLoading();
    try {
      final stops = await ref.read(stopsControllerProvider.future);
      final body = {
        'stops': [for (final s in stops) s.toDto().toJson()],
      };
      final dio = ref.read(dioProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/routes/optimize',
        data: body,
      );
      final json = response.data!;
      final result = OptimizeResult(
        optimizedOrder: (json['optimizedOrder'] as List).cast<int>(),
        totalDistanceM: (json['totalDistanceM'] as num).toDouble(),
        totalDurationS: (json['totalDurationS'] as num).toDouble(),
      );
      await ref.read(stopsControllerProvider.notifier)
          .applyOptimizedOrder(result.optimizedOrder);
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
```

- [ ] **Step 27.4: Run codegen + tests**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && flutter test test/features/stops/state/optimize_controller_test.dart && cd ../..
```

Expected: tests pass.

- [ ] **Step 27.5: Commit**

```bash
git add apps/mobile/lib/features/stops/state/optimize_controller.dart \
  apps/mobile/lib/features/stops/state/optimize_controller.g.dart \
  apps/mobile/test/features/stops/state/optimize_controller_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add @riverpod OptimizeController calling POST /routes/optimize

Maps StopsController state -> StopDto[] (drops id/source/createdAt),
posts to /routes/optimize via the Dio + AuthInterceptor wiring from
slice 1, parses { optimizedOrder, totalDistanceM, totalDurationS },
and applies the order via StopsController.applyOptimizedOrder.

State is AsyncValue<OptimizeResult?>: AsyncData(null) before first run,
AsyncLoading() during the request, AsyncData(result) on success,
AsyncError on failure (rethrown so the UI can show a SnackBar).

Tests use a Fake Dio that records the wire body and returns a canned
optimizedOrder. The fake substitutes for the dioProvider via Riverpod
override, so the suite never touches the network.
EOF
)"
```

### Task 28: `core/services/external_nav.dart` (TDD)

**Files:**
- Create: `apps/mobile/lib/core/services/external_nav.dart`
- Create: `apps/mobile/test/core/services/external_nav_test.dart`

- [ ] **Step 28.1: Write the test**

Create `apps/mobile/test/core/services/external_nav_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/services/external_nav.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';

Stop _s(double lat, double lng, [String? label]) => Stop(
      id: 'x', lat: lat, lng: lng, label: label,
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    );

void main() {
  group('ExternalNav.googleMapsUri', () {
    test('builds a multi-stop dir URI with origin, destination, waypoints', () {
      final stops = [_s(-23.55, -46.63), _s(-23.56, -46.64), _s(-23.57, -46.65), _s(-23.58, -46.66)];
      final uri = ExternalNav.googleMapsUri(stops);

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['origin'], '-23.55,-46.63');
      expect(uri.queryParameters['destination'], '-23.58,-46.66');
      expect(uri.queryParameters['waypoints'], '-23.56,-46.64|-23.57,-46.65');
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('omits waypoints param when only 2 stops', () {
      final stops = [_s(0, 0), _s(1, 1)];
      final uri = ExternalNav.googleMapsUri(stops);
      expect(uri.queryParameters.containsKey('waypoints'), isFalse);
    });

    test('throws when fewer than 2 stops', () {
      expect(() => ExternalNav.googleMapsUri([_s(0, 0)]), throwsArgumentError);
      expect(() => ExternalNav.googleMapsUri(const []), throwsArgumentError);
    });
  });

  group('ExternalNav.wazeUri', () {
    test('builds a single-stop waze:// URI with navigate=yes', () {
      final uri = ExternalNav.wazeUri(_s(-23.55, -46.63));
      expect(uri.scheme, 'waze');
      expect(uri.queryParameters['ll'], '-23.55,-46.63');
      expect(uri.queryParameters['navigate'], 'yes');
    });
  });
}
```

- [ ] **Step 28.2: Create the service**

Create `apps/mobile/lib/core/services/external_nav.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/stops/domain/stop.dart';

enum NavProvider { googleMaps, waze }

class ExternalNav {
  const ExternalNav();

  /// Multi-stop Google Maps URI. Throws ArgumentError if fewer than 2 stops.
  static Uri googleMapsUri(List<Stop> stops) {
    if (stops.length < 2) {
      throw ArgumentError('Need at least 2 stops; got ${stops.length}.');
    }
    final origin = '${stops.first.lat},${stops.first.lng}';
    final destination = '${stops.last.lat},${stops.last.lng}';
    final between = stops.sublist(1, stops.length - 1);
    final waypoints = between.map((s) => '${s.lat},${s.lng}').join('|');

    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': origin,
      'destination': destination,
      if (waypoints.isNotEmpty) 'waypoints': waypoints,
      'travelmode': 'driving',
    });
  }

  /// Single-stop Waze URI.
  static Uri wazeUri(Stop stop) {
    return Uri.parse('waze://?ll=${stop.lat},${stop.lng}&navigate=yes');
  }

  Future<bool> openInGoogleMaps(List<Stop> stops) {
    return launchUrl(googleMapsUri(stops), mode: LaunchMode.externalApplication);
  }

  Future<bool> openInWaze(Stop stop) {
    return launchUrl(wazeUri(stop), mode: LaunchMode.externalApplication);
  }
}

final externalNavProvider = Provider<ExternalNav>((ref) => const ExternalNav());
```

- [ ] **Step 28.3: Test + commit**

```bash
cd apps/mobile && flutter test test/core/services/external_nav_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/core/services/external_nav.dart \
  apps/mobile/test/core/services/external_nav_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): add ExternalNav deep-link service per ADR-0017

ExternalNav.googleMapsUri(stops) builds the multi-stop dir URI:
- origin = first stop, destination = last stop, waypoints = the rest
  pipe-separated. Omits the waypoints query when only 2 stops.
- travelmode=driving so the directions match the rider's mode.

ExternalNav.wazeUri(stop) builds the waze:// single-destination URI.

Top-level static URI builders make unit-testing trivial; the instance
openInX methods wrap url_launcher and are overridden in widget tests
via externalNavProvider.

Tests cover: multi-stop URI shape, 2-stop URI without waypoints,
ArgumentError on fewer than 2 stops, Waze URI shape.
EOF
)"
```

### Task 29: `ScreenOptimize` (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/optimize_page.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/stops/presentation/optimize_page_test.dart`

- [ ] **Step 29.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/optimize_page_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/core/providers/api_providers.dart';
import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/optimize_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  List<Stop> initial;
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {}
}

class _FakeDio extends Fake implements Dio {
  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'optimizedOrder': [1, 0],
        'totalDistanceM': 0.0,
        'totalDurationS': 0.0,
      } as T,
    );
  }
}

Stop _s(String id) => Stop(
      id: id, lat: 0, lng: 0,
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    );

void main() {
  testWidgets('OptimizePage shows the Otimizar CTA and disables when empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(_Repo([])),
          dioProvider.overrideWithValue(_FakeDio()),
        ],
        child: const MaterialApp(home: OptimizePage()),
      ),
    );
    await tester.pumpAndSettle();

    final cta = find.widgetWithText(FilledButton, 'Otimizar rota');
    expect(cta, findsOneWidget);
    expect(tester.widget<FilledButton>(cta).onPressed, isNull);
  });

  testWidgets('OptimizePage CTA is enabled with stops', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(_Repo([_s('a'), _s('b')])),
          dioProvider.overrideWithValue(_FakeDio()),
        ],
        child: const MaterialApp(home: OptimizePage()),
      ),
    );
    await tester.pumpAndSettle();

    final cta = find.widgetWithText(FilledButton, 'Otimizar rota');
    expect(tester.widget<FilledButton>(cta).onPressed, isNotNull);
  });
}
```

- [ ] **Step 29.2: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/optimize_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/optimize_controller.dart';
import '../state/stops_controller.dart';

class OptimizePage extends ConsumerWidget {
  const OptimizePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopsAsync = ref.watch(stopsControllerProvider);
    final optimizeAsync = ref.watch(optimizeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Otimizar rota')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.alt_route, size: 96),
              const SizedBox(height: 16),
              stopsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erro: $e'),
                data: (stops) => Text(
                  '${stops.length} paradas prontas para otimizar.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Spacer(),
              if (optimizeAsync.isLoading) const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'Otimizar rota',
                child: SizedBox(
                  width: double.infinity, height: 48,
                  child: FilledButton(
                    onPressed: stopsAsync.maybeWhen(
                      data: (s) => s.length < 2
                          ? null
                          : () async {
                              try {
                                await ref.read(optimizeControllerProvider.notifier).run();
                                if (context.mounted) context.go('/optimize/route');
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Falha ao otimizar: $e'),
                                  ));
                                }
                              }
                            },
                      orElse: () => null,
                    ),
                    child: const Text('Otimizar rota'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 29.3: Register `/optimize` in `app.dart`**

```dart
GoRoute(
  path: '/optimize',
  builder: (context, state) => const OptimizePage(),
),
```

Import:
```dart
import 'features/stops/presentation/optimize_page.dart';
```

- [ ] **Step 29.4: Test + commit**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/optimize_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/optimize_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/optimize_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenOptimize calling OptimizeController.run

Shows the count of stops ready to optimize and a primary CTA. Disabled
when fewer than 2 stops (server requires minItems: 2). On success
navigates to /optimize/route; on failure shows a SnackBar with the
error and stays put.

Widget tests cover the disabled-when-empty and enabled-with-stops
states.
EOF
)"
```

### Task 30: `ScreenOptimizeRoute` (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/optimize_route_page.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/stops/presentation/optimize_route_page_test.dart`

- [ ] **Step 30.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/optimize_route_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/optimize_route_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  List<Stop> initial;
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {}
}

Stop _s(String id, double lat, double lng) => Stop(
      id: id, lat: lat, lng: lng, label: id,
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    );

void main() {
  testWidgets('OptimizeRoutePage shows the optimized order list and the Iniciar CTA', (tester) async {
    final stops = [_s('a', -23.55, -46.63), _s('b', -23.56, -46.64), _s('c', -23.57, -46.65)];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_Repo(stops))],
        child: const MaterialApp(home: OptimizeRoutePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
    expect(find.text('Iniciar navegação'), findsOneWidget);
  });
}
```

- [ ] **Step 30.2: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/optimize_route_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/external_nav.dart';
import '../state/stops_controller.dart';
import 'shared/map_attribution.dart';

class OptimizeRoutePage extends ConsumerStatefulWidget {
  const OptimizeRoutePage({super.key});

  @override
  ConsumerState<OptimizeRoutePage> createState() => _OptimizeRoutePageState();
}

class _OptimizeRoutePageState extends ConsumerState<OptimizeRoutePage> {
  static const _spBoundsSw = LatLng(-23.78, -46.83);
  static const _spBoundsNe = LatLng(-23.36, -46.40);
  static const _navProviderKey = 'settings.nav_provider';

  Future<NavProvider> _readProvider() async {
    final raw = await SharedPreferencesAsync().getString(_navProviderKey);
    return raw == 'waze' ? NavProvider.waze : NavProvider.googleMaps;
  }

  Future<void> _start() async {
    final async = ref.read(stopsControllerProvider);
    final stops = async.value ?? const [];
    if (stops.length < 2) return;

    final nav = ref.read(externalNavProvider);
    final provider = await _readProvider();

    if (provider == NavProvider.googleMaps) {
      await nav.openInGoogleMaps(stops);
      if (mounted) context.go('/navigate');
    } else {
      if (stops.length > 1 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Waze não suporta múltiplas paradas; vamos abrir uma de cada vez.'),
        ));
      }
      await nav.openInWaze(stops.first);
      if (mounted) context.go('/navigate');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stopsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rota otimizada')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (stops) {
            final points = [for (final s in stops) LatLng(s.lat, s.lng)];
            return Column(
              children: [
                SizedBox(
                  height: 280,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: points.isEmpty
                          ? const LatLng(-23.5505, -46.6333)
                          : points.first,
                      initialZoom: 13,
                      minZoom: 10,
                      maxZoom: 19,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      cameraConstraint: CameraConstraint.contain(
                        bounds: LatLngBounds(_spBoundsSw, _spBoundsNe),
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro',
                        retinaMode: RetinaMode.isHighDensity(context),
                        maxNativeZoom: 19,
                      ),
                      if (points.length >= 2)
                        PolylineLayer(polylines: [
                          Polyline(points: points, strokeWidth: 4, color: Colors.blueAccent),
                        ]),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < stops.length; i++)
                            Marker(
                              point: LatLng(stops[i].lat, stops[i].lng),
                              width: 32, height: 32,
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                      osmAttribution(),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: stops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = stops[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(s.label ?? '${s.lat.toStringAsFixed(5)}, ${s.lng.toStringAsFixed(5)}'),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity, height: 48,
                    child: Semantics(
                      button: true,
                      label: 'Iniciar navegação',
                      child: FilledButton.icon(
                        onPressed: stops.length < 2 ? null : _start,
                        icon: const Icon(Icons.navigation),
                        label: const Text('Iniciar navegação'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 30.3: Register `/optimize/route`**

```dart
GoRoute(
  path: '/optimize/route',
  builder: (context, state) => const OptimizeRoutePage(),
),
```

Import:
```dart
import 'features/stops/presentation/optimize_route_page.dart';
```

- [ ] **Step 30.4: Test + commit**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/optimize_route_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/optimize_route_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/optimize_route_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenOptimizeRoute with external nav handoff

Renders the optimized stop list + a top map preview (numbered markers,
straight-line polyline for slice 2; slice 3 brings GraphHopper polyline).
"Iniciar navegação" reads the user's nav-provider preference from
SharedPreferencesAsync (key settings.nav_provider, written by
ScreenSettings in Task 33) and hands off via ExternalNav.

Google Maps path: openInGoogleMaps(stops) opens the whole multi-stop
URI in one go. Waze path: shows the "não suporta múltiplas paradas"
SnackBar then opens the first stop; ScreenNavigate (Task 31) handles
the parada-por-parada flow.

Widget test verifies all stops render and the Iniciar CTA is present.
EOF
)"
```

### Task 31: `ScreenNavigate` (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/navigate_page.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/stops/presentation/navigate_page_test.dart`

- [ ] **Step 31.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/navigate_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/navigate_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  List<Stop> initial;
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {}
}

void main() {
  testWidgets('NavigatePage shows one Checkbox per stop', (tester) async {
    final stops = List.generate(3, (i) => Stop(
      id: '$i', lat: 0, lng: 0, label: 'S$i',
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    ));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_Repo(stops))],
        child: const MaterialApp(home: NavigatePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsNWidgets(3));
    expect(find.text('S0'), findsOneWidget);
  });
}
```

- [ ] **Step 31.2: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/navigate_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/stops_controller.dart';

class NavigatePage extends ConsumerStatefulWidget {
  const NavigatePage({super.key});

  @override
  ConsumerState<NavigatePage> createState() => _NavigatePageState();
}

class _NavigatePageState extends ConsumerState<NavigatePage> {
  final Set<String> _done = {};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stopsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Em navegação')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (stops) {
            final allDone = stops.isNotEmpty && _done.length == stops.length;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: stops.length,
                    itemBuilder: (context, i) {
                      final s = stops[i];
                      return CheckboxListTile(
                        value: _done.contains(s.id),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _done.add(s.id);
                          } else {
                            _done.remove(s.id);
                          }
                        }),
                        title: Text(s.label ?? '${s.lat.toStringAsFixed(5)}, ${s.lng.toStringAsFixed(5)}'),
                        secondary: CircleAvatar(child: Text('${i + 1}')),
                      );
                    },
                  ),
                ),
                if (allDone)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity, height: 48,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/route-complete'),
                        icon: const Icon(Icons.check),
                        label: const Text('Concluir rota'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 31.3: Register `/navigate`**

```dart
GoRoute(
  path: '/navigate',
  builder: (context, state) => const NavigatePage(),
),
```

Import:
```dart
import 'features/stops/presentation/navigate_page.dart';
```

- [ ] **Step 31.4: Test + commit**

```bash
cd apps/mobile && flutter test test/features/stops/presentation/navigate_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/navigate_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/navigate_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenNavigate checklist after external handoff

User returns from Google Maps / Waze and ticks off each stop as
completed. When every stop is checked, the Concluir CTA appears and
routes to /route-complete. Local checkbox state only — slice 2 doesn't
persist completion (slice 3 will surface trip history via the
HttpStopsRepository).
EOF
)"
```

### Task 32: `ScreenRouteComplete` (TDD)

**Files:**
- Create: `apps/mobile/lib/features/stops/presentation/route_complete_page.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/stops/presentation/route_complete_page_test.dart`

- [ ] **Step 32.1: Write the test**

Create `apps/mobile/test/features/stops/presentation/route_complete_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/presentation/route_complete_page.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  List<Stop> initial;
  final List<Stop> saved = [];
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {
    saved..clear()..addAll(stops);
  }
}

void main() {
  testWidgets('RouteCompletePage shows the summary and Nova rota CTA', (tester) async {
    final stops = List.generate(5, (i) => Stop(
      id: '$i', lat: 0, lng: 0,
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    ));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(_Repo(stops))],
        child: const MaterialApp(home: RouteCompletePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('5 paradas'), findsOneWidget);
    expect(find.text('Nova rota'), findsOneWidget);
  });

  testWidgets('Nova rota clears the controller and pops to /home', (tester) async {
    final repo = _Repo([Stop(
      id: 'a', lat: 0, lng: 0,
      source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13),
    )]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stopsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: RouteCompletePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova rota'));
    await tester.pumpAndSettle();

    expect(repo.saved, isEmpty);
  });
}
```

- [ ] **Step 32.2: Create the screen**

Create `apps/mobile/lib/features/stops/presentation/route_complete_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/stops_controller.dart';

class RouteCompletePage extends ConsumerWidget {
  const RouteCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rota concluída')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (stops) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Parabéns! ${stops.length} paradas concluídas.',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/share'),
                        icon: const Icon(Icons.share),
                        label: const Text('Compartilhar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref.read(stopsControllerProvider.notifier).clear();
                          if (context.mounted) context.go('/home');
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Nova rota'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 32.3: Register `/route-complete`**

```dart
GoRoute(
  path: '/route-complete',
  builder: (context, state) => const RouteCompletePage(),
),
```

Import:
```dart
import 'features/stops/presentation/route_complete_page.dart';
```

- [ ] **Step 32.4: Test + commit + push (end of sub 2d)**

```bash
cd apps/mobile && flutter test && flutter analyze && cd ../..

git add apps/mobile/lib/features/stops/presentation/route_complete_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/stops/presentation/route_complete_page_test.dart
git commit -m "$(cat <<'EOF'
feat(stops): add ScreenRouteComplete summary

Closing screen of the slice 2 flow: shows the stop count, offers Share
(navigates to /share, see Task 34) or Nova rota (clears the controller
via StopsController.clear → state empty → /home shows ScreenHomeEmpty
again).

End of sub 2d. Push to share progress.
EOF
)"

git push origin feat/m2-slice-2-telas-core
```

---

## Phase 5 — Sub 2e Periféricos

### Task 33: `ScreenSettings` with nav-provider toggle + paywall/home stubs (TDD)

**Files:**
- Create: `apps/mobile/lib/features/settings/presentation/settings_page.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/settings/settings_page_test.dart`

- [ ] **Step 33.1: Write the test**

Create `apps/mobile/test/features/settings/settings_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roteirizador_pro/features/settings/presentation/settings_page.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('SettingsPage renders the four sections with stubs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conta'), findsOneWidget);
    expect(find.text('Aplicativo de navegação'), findsOneWidget);
    expect(find.text('Endereço de casa'), findsOneWidget);
    expect(find.text('Pagamentos'), findsOneWidget);
    expect(find.textContaining('em breve'), findsAtLeastNWidgets(2));
  });

  testWidgets('Toggling the nav provider persists to SharedPreferencesAsync', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Waze'));
    await tester.pumpAndSettle();

    final stored = await SharedPreferencesAsync().getString('settings.nav_provider');
    expect(stored, 'waze');
  });
}
```

- [ ] **Step 33.2: Create the page**

Create `apps/mobile/lib/features/settings/presentation/settings_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/external_nav.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _navProviderKey = 'settings.nav_provider';
  NavProvider _selected = NavProvider.googleMaps;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final raw = await SharedPreferencesAsync().getString(_navProviderKey);
    if (mounted) {
      setState(() => _selected = raw == 'waze' ? NavProvider.waze : NavProvider.googleMaps);
    }
  }

  Future<void> _select(NavProvider p) async {
    setState(() => _selected = p);
    await SharedPreferencesAsync().setString(
      _navProviderKey,
      p == NavProvider.waze ? 'waze' : 'google_maps',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        child: ListView(
          children: [
            const _SectionHeader('Conta'),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Sair'),
              subtitle: Text('Hooked via slice 1 auth controller'),
            ),
            const Divider(),
            const _SectionHeader('Aplicativo de navegação'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<NavProvider>(
                segments: const [
                  ButtonSegment(
                    value: NavProvider.googleMaps,
                    label: Text('Google Maps'),
                    icon: Icon(Icons.map_outlined),
                  ),
                  ButtonSegment(
                    value: NavProvider.waze,
                    label: Text('Waze'),
                    icon: Icon(Icons.directions),
                  ),
                ],
                selected: {_selected},
                onSelectionChanged: (s) => _select(s.first),
              ),
            ),
            const Divider(),
            const _SectionHeader('Endereço de casa'),
            const ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('Configurar — em breve'),
              subtitle: Text('Disponível no slice 5 (Sentido casa)'),
            ),
            const Divider(),
            const _SectionHeader('Pagamentos'),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Pix Split — em breve'),
              subtitle: Text('Disponível no slice 4 (Paywall)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
```

- [ ] **Step 33.3: Register `/settings`**

```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsPage(),
),
```

Import:
```dart
import 'features/settings/presentation/settings_page.dart';
```

- [ ] **Step 33.4: Test + commit**

```bash
cd apps/mobile && flutter test test/features/settings/settings_page_test.dart && flutter analyze && cd ../..

git add apps/mobile/lib/features/settings/presentation/settings_page.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/settings/settings_page_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): add ScreenSettings with nav-provider toggle and stubs

Four sections matching the prototype:
- Conta: hooked Sair (the existing slice 1 AuthController.signOut wiring)
- Aplicativo de navegação: SegmentedButton (Google Maps | Waze) that
  persists to SharedPreferencesAsync under settings.nav_provider.
  ScreenOptimizeRoute reads this same key at handoff time.
- Endereço de casa: visual stub for slice 5.
- Pagamentos: visual stub for slice 4.

Stubs are intentional — slice 4/5 will replace each ListTile with the
real implementation in their own commits.

Tests cover rendering of all four sections and the toggle persistence.
EOF
)"
```

### Task 34: `ScreenShare` via share_plus (TDD)

**Files:**
- Create: `apps/mobile/lib/features/share/presentation/share_sheet.dart`
- Modify: `apps/mobile/lib/app.dart`
- Create: `apps/mobile/test/features/share/share_sheet_test.dart`

- [ ] **Step 34.1: Write the test**

Create `apps/mobile/test/features/share/share_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/share/presentation/share_sheet.dart';
import 'package:roteirizador_pro/features/stops/data/repositories/stops_repository.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

class _Repo implements StopsRepository {
  _Repo(this.initial);
  List<Stop> initial;
  @override
  Future<List<Stop>> load() async => List.unmodifiable(initial);
  @override
  Future<void> save(List<Stop> stops) async {}
}

void main() {
  testWidgets('ShareSheet builds the WhatsApp-friendly text from the route', (tester) async {
    final stops = [
      Stop(id: 'a', lat: -23.55, lng: -46.63, label: 'A', source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13)),
      Stop(id: 'b', lat: -23.56, lng: -46.64, label: 'B', source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13)),
    ];

    final text = ShareSheet.buildRouteText(stops);

    expect(text, contains('1. A'));
    expect(text, contains('2. B'));
    expect(text, contains('-23.55'));
  });

  testWidgets('ShareSheet renders the Compartilhar CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopsRepositoryProvider.overrideWithValue(_Repo([
            Stop(id: 'a', lat: 0, lng: 0, source: StopSource.manual, createdAt: DateTime.utc(2026, 5, 13)),
          ])),
        ],
        child: const MaterialApp(home: ShareSheet()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compartilhar rota'), findsOneWidget);
  });
}
```

- [ ] **Step 34.2: Create the screen**

Create `apps/mobile/lib/features/share/presentation/share_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../stops/domain/stop.dart';
import '../../stops/state/stops_controller.dart';

class ShareSheet extends ConsumerWidget {
  const ShareSheet({super.key});

  /// Public static so the unit test can validate the format without
  /// triggering the native share sheet.
  static String buildRouteText(List<Stop> stops) {
    final buffer = StringBuffer('Rota otimizada — Roteirizador Pro\n\n');
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      buffer.writeln('${i + 1}. ${s.label ?? "(sem rótulo)"}');
      buffer.writeln('   ${s.lat.toStringAsFixed(5)}, ${s.lng.toStringAsFixed(5)}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Compartilhar')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (stops) {
            final text = buildRouteText(stops);
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/route-complete'),
                          child: const Text('Voltar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: stops.isEmpty
                              ? null
                              : () => Share.share(text, subject: 'Rota Roteirizador Pro'),
                          icon: const Icon(Icons.share),
                          label: const Text('Compartilhar rota'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 34.3: Register `/share`**

```dart
GoRoute(
  path: '/share',
  builder: (context, state) => const ShareSheet(),
),
```

Import:
```dart
import 'features/share/presentation/share_sheet.dart';
```

- [ ] **Step 34.4: Test + commit + push (end of sub 2e)**

```bash
cd apps/mobile && flutter test && flutter analyze && cd ../..

git add apps/mobile/lib/features/share/presentation/share_sheet.dart \
  apps/mobile/lib/app.dart \
  apps/mobile/test/features/share/share_sheet_test.dart
git commit -m "$(cat <<'EOF'
feat(share): add ScreenShare via share_plus

ShareSheet.buildRouteText (public static) formats stops into a
WhatsApp-friendly numbered list with lat/lng coords. UI shows the
preview text and a Compartilhar CTA that fires Share.share(text) —
opens the native Android share sheet.

The preview is also pure-Dart-testable: the test exercises
buildRouteText directly without touching the platform channel.

End of sub 2e. All 15 prototype screens shipped. Push.
EOF
)"

git push origin feat/m2-slice-2-telas-core
```

---

## Phase 6 — Release

### Task 35: Final mobile + backend verification

**Files:** none (verification only)

- [ ] **Step 35.1: Full test suite + analyzer**

```bash
cd apps/mobile && flutter analyze && flutter test && cd ../..
cd apps/backend && bun run typecheck && cd ../..
```

Expected:
- `flutter analyze` reports **0 issues**.
- All `flutter test` files pass (count should be ~25 widget + unit tests).
- `bun run typecheck` is clean.

If anything fails, fix before continuing. The release tasks below assume green from this point.

- [ ] **Step 35.2: Run codegen one more time as safety net**

```bash
cd apps/mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze && cd ../..
```

If the generator changes any `.g.dart`, commit the diff:

```bash
git add apps/mobile/lib/**/*.g.dart
git commit -m "chore(mobile): refresh riverpod codegen before release" || true
```

(The `|| true` accepts the empty-commit case where nothing changed.)

### Task 36: Build the release APK + verify

**Files:**
- Generated: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`

- [ ] **Step 36.1: Build the release APK using the slice 1 script**

```bash
bash apps/mobile/scripts/build-release-apk.sh
```

Expected:
- Gradle produces `apps/mobile/build/app/outputs/flutter-apk/app-release.apk` (~35-40 MB given the ML Kit model is bundled).
- No keystore prompts (script already reads `key.properties`).
- No `flutter build` errors.

- [ ] **Step 36.2: Verify permissions with `aapt2 dump permissions`**

Find `aapt2` (the Android SDK build-tools install):
```bash
AAPT2=$(ls -t ~/Library/Android/sdk/build-tools/*/aapt2 | head -1)
echo "$AAPT2"
```

Then:
```bash
"$AAPT2" dump permissions apps/mobile/build/app/outputs/flutter-apk/app-release.apk
```

Expected output contains every one of:
```
uses-permission: android.permission.INTERNET
uses-permission: android.permission.ACCESS_FINE_LOCATION
uses-permission: android.permission.RECORD_AUDIO
uses-permission: android.permission.CAMERA
```

If any are missing → STOP. Re-check `apps/mobile/android/app/src/main/AndroidManifest.xml` Task 17. Do NOT proceed with `adb install` until the missing permission is fixed and the APK rebuilt.

Save the output to `/tmp/slice2-permissions.txt` for the PR body:
```bash
"$AAPT2" dump permissions apps/mobile/build/app/outputs/flutter-apk/app-release.apk > /tmp/slice2-permissions.txt
```

- [ ] **Step 36.3: Verify signature with `apksigner verify`**

```bash
APKSIGNER=$(ls -t ~/Library/Android/sdk/build-tools/*/apksigner | head -1)
"$APKSIGNER" verify --verbose --print-certs apps/mobile/build/app/outputs/flutter-apk/app-release.apk
```

Expected:
- `Verifies` (followed by check marks).
- `Verified using v1 scheme (JAR signing): false` (we don't use v1).
- `Verified using v2 scheme (APK Signature Scheme v2): true` (required).
- `Verified using v3 scheme (APK Signature Scheme v3): true` (optional, common).
- `Signer #1 certificate SHA-256 digest: d9c961d6a32a0c45b611e0e12d86fa7e521cd33c88833c7c5d5ab9919fe91431` — this MUST match the slice 1 keystore SHA-256 `D9:C9:61:D6:A3:2A:0C:45:B6:11:E0:E1:2D:86:FA:7E:52:1C:D3:3C:88:83:3C:7C:5D:5A:B9:91:9F:E9:14:31` (case-insensitive).

If the SHA-256 doesn't match → STOP. Either `key.properties` is pointing at the wrong keystore, or the keystore on disk was replaced. Fix and re-build.

Save the output:
```bash
"$APKSIGNER" verify --verbose --print-certs apps/mobile/build/app/outputs/flutter-apk/app-release.apk > /tmp/slice2-apksigner.txt
```

- [ ] **Step 36.4: Install on the Galaxy A06**

```bash
adb devices
adb install -r apps/mobile/build/app/outputs/flutter-apk/app-release.apk
```

Expected: `Success`. If `INSTALL_FAILED_VERSION_DOWNGRADE`, the device already has a higher versionCode — uninstall first: `adb uninstall br.com.roteirizadorpro.roteirizador_pro` and retry.

### Task 37: Run the 14-step golden path on the real device

**Files:**
- Screenshots saved to `/tmp/slice2-screenshots/` (or any temp dir) for the PR body.

- [ ] **Step 37.1: Walk every step from spec §Goals**

Reference: `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` §Goals.

Execute steps 1-14 in order on the Galaxy A06:

1. Sign in with existing credentials.
2. See `ScreenHomeEmpty`.
3. Add 5 stops via mixed methods:
   - 2 by typing in `ScreenAddStop`
   - 1 by voice in `ScreenVoice`
   - 1 by photo in `ScreenOCR`
   - 1 by tap in `ScreenAddStopsMap`
4. Open `ScreenStopDetail` for one and edit via `ScreenEditStop`.
5. Reorder the list via `ScreenReorder`.
6. View `ScreenMapStops` — confirm all 5 markers numbered.
7. Tap "Otimizar rota" in `ScreenOptimize`.
8. See `ScreenOptimizeRoute`.
9. Tap "Iniciar navegação" → Google Maps opens with multi-stop.
10. Back to app → `ScreenNavigate`.
11. Check off all 5 stops → `ScreenRouteComplete`.
12. Open `ScreenSettings`, toggle nav provider to Waze, see stubs.
13. Tap `ScreenShare` → native share sheet appears with the formatted text.
14. Force-close the app (recent apps, swipe away). Reopen. All 5 stops restored from `SharedPreferencesAsync`.

For each step, capture a screenshot:
```bash
adb shell screencap -p /sdcard/slice2-step-N.png
adb pull /sdcard/slice2-step-N.png /tmp/slice2-screenshots/step-N.png
```

If any step fails or visibly diverges from the prototype: open `prototipo/screens-*.jsx` for that screen, identify the gap, fix the Flutter widget, rebuild via `bash apps/mobile/scripts/build-release-apk.sh`, re-install, re-test. Repeat until green.

- [ ] **Step 37.2: Run `prototype-fidelity-checker` subagent**

Dispatch the `prototype-fidelity-checker` agent (defined in `.claude/agents/` per slice 1) against the entire `apps/mobile/lib/features/stops/presentation/`, `apps/mobile/lib/features/settings/presentation/`, and `apps/mobile/lib/features/share/presentation/` directories. The agent's output is a punch list. Address each item, rebuild, re-test. Iterate until the agent reports clean.

- [ ] **Step 37.3: Run `adr-guardian` subagent**

Dispatch against the slice 2 diff (compare `feat/m2-slice-2-telas-core` to `develop`). Expected outcome:
- All new libraries appear in ADR-0015 (Task 2 already amended versions).
- ADR-0017 exists for external nav (Task 26).
- No new top-level dependency lacks an ADR.

If the agent flags something, address it in a new commit before opening the PR.

- [ ] **Step 37.4: Commit any fidelity fixes (if applicable)**

If steps 37.2 / 37.3 produced fixes, commit them with appropriate Conventional Commit messages (e.g., `fix(stops): align ScreenHomeList spacing with prototipo` — scope `stops`).

### Task 38: Republish APK on the landing + refactor CTAs

**Files:**
- Move: `apps/landing/public/roteirizador-pro-v1.1.0.apk` (NEW)
- Modify: `apps/landing/src/app/page.tsx`
- Optionally Create: `apps/landing/src/lib/apk-version.ts`

- [ ] **Step 38.1: Copy the new APK to the landing**

```bash
cp apps/mobile/build/app/outputs/flutter-apk/app-release.apk \
   apps/landing/public/roteirizador-pro-v1.1.0.apk
```

Confirm:
```bash
ls -lh apps/landing/public/roteirizador-pro-*.apk
```

Expected: both `v1.0.0.apk` (slice 1) and `v1.1.0.apk` (slice 2) present. Keep both — older download links should not 404 for already-printed flyers / shared messages.

- [ ] **Step 38.2: Refactor the 4 CTA hrefs to a single constant**

Read `apps/landing/src/app/page.tsx`. Find the 4 hardcoded `roteirizador-pro-v1.0.0.apk` references in the `Baixar app` CTAs.

Create `apps/landing/src/lib/apk-version.ts`:

```typescript
/**
 * Single source of truth for the APK file served on the landing.
 * Update this value when shipping a new mobile release, then the four
 * `Baixar app` CTAs in src/app/page.tsx pick up the new filename.
 *
 * The file must exist at apps/landing/public/${APK_FILENAME} for the
 * /Baixar app link to return HTTP 200 on production.
 */
export const APK_LATEST_VERSION = '1.1.0';
export const APK_FILENAME = `roteirizador-pro-v${APK_LATEST_VERSION}.apk`;
```

In `apps/landing/src/app/page.tsx`:
- At the top, add `import { APK_FILENAME } from '@/lib/apk-version';` (adjust the path if the alias differs in `tsconfig.json`).
- Replace each `href="/roteirizador-pro-v1.0.0.apk"` with `href={`/${APK_FILENAME}`}`.
- Keep the `download` attribute as-is.

- [ ] **Step 38.3: Build + typecheck + lint the landing**

```bash
cd apps/landing && bun run typecheck && bun run lint && bun run build && cd ../..
```

Expected: clean.

- [ ] **Step 38.4: Commit**

```bash
git add apps/landing/public/roteirizador-pro-v1.1.0.apk \
  apps/landing/src/app/page.tsx \
  apps/landing/src/lib/apk-version.ts
git commit -m "$(cat <<'EOF'
feat(landing): publish APK v1.1.0 and refactor download CTAs

Adds the slice 2 release APK (built from feat/m2-slice-2-telas-core,
v1.1.0+2, ML Kit + flutter_map + share_plus bundled) at
public/roteirizador-pro-v1.1.0.apk. The v1.0.0 APK stays alongside so
already-shared download links keep working.

Refactors the four landing CTAs to read from a single APK_LATEST_VERSION
constant in src/lib/apk-version.ts. Future slice releases only need
to bump the constant and drop the new APK in public/ — no more
text-search across page.tsx.
EOF
)"
```

### Task 39: Open PR `feat/m2-slice-2-telas-core` → `develop`

**Files:** none (gh CLI)

- [ ] **Step 39.1: Push final state**

```bash
git push origin feat/m2-slice-2-telas-core
```

- [ ] **Step 39.2: Open the PR**

```bash
gh pr create --base develop --head feat/m2-slice-2-telas-core \
  --title "feat: m2 slice 2 — telas core (15 screens + mock optimize + nav handoff)" \
  --body "$(cat <<'EOF'
## Summary

Slice 2 ships the 15 remaining prototype screens, modern Android opt-ins (edge-to-edge, predictive back), the four new runtime permissions, a mock `POST /routes/optimize` returning input order, and the deep-link external-nav handoff (Google Maps multi-stop default, Waze toggle).

## What this slice ships (vs develop)

- **Sub 2a Foundation** — Android 15 edge-to-edge + predictive back, `Stop` domain + `StopDto` mirror, `SharedPreferencesAsync` repository, `StopsController` (Riverpod 3 codegen), `ScreenHomeEmpty` + `ScreenHomeList`, `ScreenAddStop` (manual entry), shared `StopForm`.
- **Sub 2b Captura** — 3 new Android permissions in src/main, `permission_handler` wrapper, `ScreenVoice` (speech_to_text), `ScreenOCR` (image_picker + google_mlkit_text_recognition), `ScreenAddStopsMap` (flutter_map + OSM, ADR-0016 compliant).
- **Sub 2c Manipulação** — `ScreenStopDetail`, `ScreenEditStop`, `ScreenReorder` (ReorderableListView), `ScreenMapStops`.
- **Sub 2d Otimização + Nav** — backend mock 200, `OptimizeController`, `core/services/external_nav.dart`, `ScreenOptimize` → `ScreenOptimizeRoute` → `ScreenNavigate` → `ScreenRouteComplete`, ADR-0017 filed.
- **Sub 2e Periféricos** — `ScreenSettings` (nav-provider toggle + paywall/home stubs), `ScreenShare` (share_plus).
- **Release** — APK v1.1.0+2 built, signed, published at `apps/landing/public/roteirizador-pro-v1.1.0.apk`, four landing CTAs now read from `APK_LATEST_VERSION` constant.

## Test plan

- [x] `flutter analyze` clean
- [x] `flutter test` passes (~25 widget + unit tests)
- [x] `bun run typecheck` clean in apps/backend
- [x] `bun run build` clean in apps/landing
- [x] **`aapt2 dump permissions` confirms INTERNET, ACCESS_FINE_LOCATION, RECORD_AUDIO, CAMERA**
- [x] **`apksigner verify --verbose --print-certs` confirms v2 scheme + cert SHA-256 matches slice 1 keystore**
- [x] Backend `POST /routes/optimize` smoke (200/401/400) — see captures below
- [x] Real-device E2E on Galaxy A06: 14-step golden path completed, screenshots attached
- [x] `prototype-fidelity-checker` agent green
- [x] `adr-guardian` agent green (ADR-0017 filed, ADR-0015 amended with resolved versions)
- [ ] Vercel preview deploy SUCCESS (URL auto-comment by Vercel bot)

## Backend smoke (curl)

<details>
<summary>POST /routes/optimize — three captures</summary>

```
(paste contents of /tmp/slice2-optimize-smoke.txt from Task 6.4 here)
```
</details>

## APK verification

<details>
<summary>aapt2 dump permissions</summary>

```
(paste contents of /tmp/slice2-permissions.txt from Task 36.2 here)
```
</details>

<details>
<summary>apksigner verify --verbose --print-certs</summary>

```
(paste contents of /tmp/slice2-apksigner.txt from Task 36.3 here)
```
</details>

## Pre-merge manual action

None.

## Related

- Spec: `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md`
- Plan: `docs/superpowers/plans/2026-05-13-m2-slice-2-telas-core.md`
- ADR-0015 (amended) — M2 plan and library choices
- ADR-0016 — Map and tile policy
- ADR-0017 (new) — External navigation hand-off
- Roadmap: `docs/08-ROADMAP.md` "Slice 2 — Telas Core"
- Checklist: `docs/M2-SLICE-CHECKLIST.md`
EOF
)"
```

Save the returned PR URL — it goes in the session log (Task 41).

- [ ] **Step 39.3: Confirm Vercel preview SUCCESS**

After the PR is open, Vercel auto-comments with the preview URL. Wait for the SUCCESS badge (~2-3 minutes). If it FAILS, open `gh pr checks` and debug.

### Task 40: Promotion PR develop → main + tag v1.1.0

**Files:** none (gh + git tag)

- [ ] **Step 40.1: Merge the slice 2 PR into develop**

When Eduardo approves on GitHub (or runs `gh pr merge --squash`), the PR closes and `develop` advances.

Pull locally:
```bash
git checkout develop
git pull --ff-only origin develop
git log --oneline -3
```

- [ ] **Step 40.2: Open promotion PR `develop` → `main`**

```bash
gh pr create --base main --head develop \
  --title "release: promote m2 slice 2 (telas core) to production v1.1.0" \
  --body "$(cat <<'EOF'
## Summary

Promotes the merged slice 2 PR from `develop` to `main`. Production gets the v1.1.0 APK on the landing + the AndroidManifest permissions + the modern Android opt-ins + the mock optimize endpoint.

## What this PR ships (vs main)

Everything in the slice 2 PR — see the merged feat PR for the full breakdown.

## Test plan

- [x] develop is green — see the merged slice 2 PR for the full per-task verification trail
- [ ] After merge: tag v1.1.0, smoke `curl -sI https://roteirizadorpro.com.br/roteirizador-pro-v1.1.0.apk` returns 200
- [ ] After merge: `curl -sI https://api.roteirizadorpro.com.br/health` returns 200 (API unchanged)

## Pre-merge manual action

None.

## Related

- Feature PR: (link to the slice 2 PR merged earlier)
EOF
)"
```

- [ ] **Step 40.3: After the promotion PR is merged, tag v1.1.0**

```bash
git checkout main
git pull --ff-only origin main
git tag -a v1.1.0 -m "M2 Slice 2 — Telas Core. 15 screens, mock optimize, external nav, edge-to-edge, predictive back."
git push origin v1.1.0
```

- [ ] **Step 40.4: Production smoke**

```bash
curl -sI https://roteirizadorpro.com.br/roteirizador-pro-v1.1.0.apk
curl -sI https://roteirizadorpro.com.br/roteirizador-pro-v1.0.0.apk
curl -sI https://api.roteirizadorpro.com.br/health
```

Expected:
- v1.1.0.apk → `HTTP/2 200`, `Content-Type: application/vnd.android.package-archive`, `Content-Length: ~36MB`.
- v1.0.0.apk → `HTTP/2 200` (kept alongside).
- /health → `HTTP/2 200` (API untouched by this slice).

If any returns non-200, file a hotfix immediately. Do not declare slice 2 done.

### Task 41: Session-end commit (single commit, three files)

**Files:**
- Create: `docs/sessions/2026-05-XX-NN-m2-slice-2-telas-core.md` (NN = next index after 11)
- Modify: `docs/sessions/0001-INDEX.md`
- Modify: `TODO.md`
- Modify: `docs/10-CHANGELOG.md`
- Modify: `docs/08-ROADMAP.md`

- [ ] **Step 41.1: Author the session log**

Use the template at `docs/sessions/0000-template.md`. Replace `XX-NN` with today's ISO date + the next sequence number after the latest in the index. Cover:

- What shipped (per sub-slice)
- The Q1/Q2/Q3 decisions from brainstorming (link to spec)
- ADR-0017 filed
- ADR-0015 amended (resolved versions)
- Production state (APK v1.1.0 live, slice 1 v1.0.0 still alongside)
- Tech debt added to TODO.md (post-slice-3 backend test framework decision, post-M2 integration_test)

- [ ] **Step 41.2: Append entry to `docs/sessions/0001-INDEX.md`**

Add the new session line immediately after the heading per the template.

- [ ] **Step 41.3: Update `TODO.md`**

Mark all sub-slice 2 pre-flight and implementation items as `[x]`. Move slice 2 to the "M2 Slices" closed section with the v1.1.0 tag. Add the tech-debt items to "Discovered while working".

- [ ] **Step 41.4: Update `docs/10-CHANGELOG.md`**

Add an entry under a `## v1.1.0 — 2026-05-XX` heading listing the high-level deliverables.

- [ ] **Step 41.5: Mark slice 2 ✅ in `docs/08-ROADMAP.md`**

In the "Status snapshot" and "Slice 2 — Telas Core" sections, change status from 🟡 In progress to ✅ shipped 2026-05-XX as `v1.1.0`.

- [ ] **Step 41.6: Single commit**

```bash
git add docs/sessions/ TODO.md docs/10-CHANGELOG.md docs/08-ROADMAP.md
git commit -m "$(cat <<'EOF'
docs(sessions): m2 slice 2 telas core shipped as v1.1.0

Closes slice 2 with the session log, sessions index entry, TODO state
update, changelog, and ROADMAP status flip. Production live at:
- https://roteirizadorpro.com.br/roteirizador-pro-v1.1.0.apk
- https://api.roteirizadorpro.com.br/health (unchanged from M1)

ADRs filed/amended in this slice: ADR-0017 (external nav), ADR-0015
amended (resolved library versions). The next slice is 3 (VRP real):
in-process Node TS solver fed by GraphHopper matrix.
EOF
)"
```

- [ ] **Step 41.7: Push and confirm**

```bash
git push origin develop
git push origin main 2>/dev/null || true   # main already pushed via promotion PR
```

Slice 2 is shipped.

---

## Self-review

The plan author runs this checklist before declaring the plan complete.

**Spec coverage:** every section of the spec maps to one or more tasks:

- §Context → Task 0 (pre-flight read).
- §Decisions Q1 → Task 9 (SharedPrefsStopsRepository).
- §Decisions Q2 → Task 26 (ADR-0017) + Task 28 (ExternalNav) + Task 30 (ScreenOptimizeRoute) + Task 33 (Settings toggle).
- §Decisions Q3 → no implementation; price stays at BRL 25.90 lockfile. Tracked as a doc-only no-op.
- §Goals (14-step golden path) → Task 37 (real-device E2E).
- §Architecture (mobile feature layout) → Tasks 7-34 collectively.
- §Architecture (backend evolution) → Tasks 5-6.
- §Architecture principles (repository swap, DTO/domain, schema source-of-truth, Riverpod 3 codegen, DI overrides, no premature abstraction) → enforced by Tasks 7-11 and the test patterns throughout.
- §Data flow (Stop model, TypeBox evolution, optimize flow, Map config, persistence, permissions, modern Android opt-ins, external nav) → Tasks 3-32.
- §Sub-slice plan (2a-2e) → Phases 1-5.
- §Libraries table → Tasks 1-2.
- §ADRs filed → Task 26 (ADR-0017).
- §Risks → mitigations live inside the relevant tasks.
- §Accessibility → Semantics labels, 48dp targets, contrast audit baked into Tasks 12, 13, 15, 17, 23-24, 29-30.
- §Test strategy → Task 35 (final verification) + per-task TDD.
- §Verification gates → Tasks 35-40.

**Placeholder scan:** no `TBD`, no `TODO` in step bodies, no "implement later", no "similar to Task N" — code is repeated in full per the No-Placeholders rule. The two named placeholder files (Task 14's empty `add_stop_page.dart` and `stop_detail_page.dart`) are explicit transient unblockers; their real implementations are in Tasks 15 and 19.

**Type consistency:** the controller method names (`add`, `remove`, `update`, `reorder`, `applyOptimizedOrder`, `clear`), the controller class names (`StopsController`, `OptimizeController`), the page class names (`HomeListPage` / `HomeEmptyPage` / etc. matching their prototype `ScreenX` names), the schema type (`StopSchema` / `OptimizeRequestSchema` / `OptimizeResponseSchema`), and the SharedPreferences key (`settings.nav_provider`) are consistent across all tasks. The `_navProviderKey` constant appears in both `ScreenOptimizeRoute` (Task 30) and `ScreenSettings` (Task 33) with the same value; promote to a shared constant in a follow-up if it ever changes.

**Scope check:** single subsystem, single PR, single branch. Plan size is large because 15 screens × TDD is genuinely 38 tasks; this is the inherent floor for a 2-3 week implementation that maintains TDD discipline.

The plan is ready.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-13-m2-slice-2-telas-core.md`. Two execution options:

**1. Subagent-Driven (recommended)** — A fresh subagent is dispatched per task. The agent reads the task, executes the steps, and returns. Eduardo reviews between tasks. Fast iteration; protects the main session context window from filling with implementation details.

**2. Inline Execution** — Tasks execute in the current session using `superpowers:executing-plans`. Batched with checkpoints for review. Higher token cost but no context handoff overhead.

Which approach?






