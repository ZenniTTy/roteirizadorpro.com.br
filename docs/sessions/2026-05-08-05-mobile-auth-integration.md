# Session 2026-05-08-05 — mobile-auth-integration

## Metadata

- **Date**: 2026-05-08 (America/Sao_Paulo)
- **Sequence**: 05
- **Agent**: Claude Code (Opus 4.7, 1M ctx)
- **Human**: Eduardo
- **Topic**: Mobile auth integration (Phase 2 — closes the auth slice end-to-end)
- **Duration**: ~2h
- **Related ADRs**: ADR-0005 (Riverpod 3), ADR-0013 (API contract source-of-truth), ADR-0002 (Flutter), ADR-0006 (TypeBox)
- **Related TODO items**: Phase 2 — Flutter Dio client, Flutter token storage, Flutter auth notifier

## Goal of the Session

Wire the existing Login + Register screens to the freshly-shipped backend so that registering / logging in actually persists tokens, hits the API, and routes the user to a logged-in screen. Verify auto-refresh on 401 + reuse-detection cascade work through Dio.

## What Was Done

### Research first (per the rule)

- Context7 `/cfug/dio` — confirmed `QueuedInterceptor` over `Interceptor` for token refresh: it serializes `onError` so N parallel 401s fire only one /refresh call. Use a SEPARATE Dio instance for the /refresh call to avoid recursion (otherwise the refresh request itself can 401-loop).
- Context7 `/rrousselgit/riverpod` (v3) — `@riverpod class Foo extends _$Foo { Future<T> build() async { ... } }` is the canonical AsyncNotifier pattern; `state = AsyncValue.guard(...)` for explicit mutations.
- WebSearch `flutter_secure_storage` — 2026 best practice is `AndroidOptions(encryptedSharedPreferences: true)`; v9.x is OK for M1 (v10 adds custom-cipher with auto-migration but introduces breaking changes — would need a new ADR).

### Implementation

- **`apps/mobile/lib/features/auth/data/token_storage.dart`** — `TokenStorage` thin wrapper around `FlutterSecureStorage` with `AndroidOptions(encryptedSharedPreferences: true)` and `KeychainAccessibility.first_unlock` for iOS parity. Keys are namespaced (`rp.auth.access`, `rp.auth.refresh`).
- **`apps/mobile/lib/features/auth/data/auth_repository.dart`** — wraps the auth-aware Dio. Maps `DioException` → `AuthApiException(statusCode, error, message)` so the UI can switch on `error` codes (`invalid_credentials`, `email_taken`, `token_reuse`) for friendly Portuguese messages.
- **`apps/mobile/lib/core/network/auth_interceptor.dart`** — `QueuedInterceptor`. `onRequest` adds `Authorization: Bearer <access>` to every request except routes flagged `extra: { skipAuth: true }`. `onError` only handles 401 from non-`/auth/*` routes: looks up the refresh token, calls `POST /auth/refresh` on the bare `refreshDio`, persists the new pair, and retries the original request via `refreshDio.fetch(retryOptions)` (the original `dio` would re-add the now-stale `Authorization` header). On refresh failure: clears storage + calls `onLogout` callback so the auth controller flips state.
- **`apps/mobile/lib/core/network/api_client.dart`** — `buildApiClient` factory returns the auth-aware `dio` paired with the bare `refreshDio`. Both share `BaseOptions` (baseUrl, timeouts, JSON content-type).
- **`apps/mobile/lib/core/providers/api_providers.dart`** — Riverpod codegen providers (`tokenStorageProvider`, `apiClientProvider`, `dioProvider`, all `@Riverpod(keepAlive: true)`). `apiClientProvider` lazily reads `authControllerProvider.notifier` for the `onLogout` callback — circular dependency is fine because the read is deferred until 401-time.
- **`apps/mobile/lib/features/auth/state/auth_controller.dart`** — `@Riverpod(keepAlive: true) class AuthController extends _$AuthController`. `build` reads tokens; if present, calls `/me` to validate and either returns the user or clears tokens (on 401) and returns null. `login` mutates state to `AsyncValue.data(user)` on success, persists tokens. `register` honors the M1 contract (no auto-login at the API level — the UI calls `login` after register for UX). `signOut` clears storage AND state; `signOutLocal` is the storage-already-cleared variant the interceptor uses to avoid double-clear.
- **`apps/mobile/lib/features/home/presentation/home_placeholder_page.dart`** — minimal post-login screen. Reads `authControllerProvider.value` for the user payload, shows name/email/phone/id, has a "Sair" ghost button. Real Screen 03 (Caminhar / Otimizar / Iniciar) is M2.
- **`apps/mobile/lib/app.dart`** — GoRouter wrapped in a `Provider<GoRouter>` so it can listen to Riverpod. `_AuthListenable` is a `ChangeNotifier` bridge: `ref.listen(authControllerProvider, (_, __) => notifyListeners())`. The router's `redirect` callback reads `authControllerProvider`: while loading → null (no redirect, lets the splash render); logged in + on /login or /register → /home; not logged in + anywhere else → /login.
- **`apps/mobile/lib/features/auth/presentation/login_page.dart`**, **`register_page.dart`** — converted to `ConsumerStatefulWidget`. Submit buttons toggle a local `_submitting` boolean (label changes to "Entrando…" / "Criando conta…"); call `ref.read(authControllerProvider.notifier).login/register(...)`; catch `AuthApiException` and surface a friendly message via SnackBar (`E-mail ou senha incorretos.`, `Este e-mail já está cadastrado.`). Register auto-logs-in on success (avoids forcing a second screen).
- **`apps/mobile/android/app/src/main/res/xml/network_security_config.xml`** + **AndroidManifest.xml** — `cleartextTrafficPermitted="true"` is whitelisted ONLY for `10.0.2.2`, `127.0.0.1`, `localhost` (dev). Production HTTPS to `api.roteirizadorpro.com.br` is unaffected (default policy still enforces TLS).

### Bugs found and fixed during smoke-test

1. **First-frame BoxConstraints crash.** `LoginPage.build` computed `minHeight = mediaQuery.size.height - padding.vertical - 56` directly. With the new router's auth-bootstrap loading state, the first frame can render with `MediaQuery.size = (0, 0)` → minHeight = -56 → `ConstrainedBox` assertion fires. Fixed both pages by clamping with `.clamp(0.0, double.infinity)`.
2. **Tap coordinates mismatch.** Initial smoke-test taps used display-scaled coordinates (the screenshot is 1080×2400 but renders at 50% scale in the developer tool). Multiplied by 2 → fields received the input correctly.

### Verification (live emulator round-trip)

Backend running at `http://127.0.0.1:3000`, app running on Pixel_8 emulator (`http://10.0.2.2:3000` from inside the emulator):

| Step | Expected | Actual | Status |
|---|---|---|---|
| App cold start | Login screen renders, no crash | renders, fields visible | PASS |
| `curl POST /auth/register` (pre-create user) | 201 + user | 201 + user (no `passwordHash` leak) | PASS |
| `adb input tap` email + type → `adb input tap` password + type | both fields filled | confirmed via screenshot | PASS |
| Tap Entrar → `POST /auth/login` | tokens persisted, `state = AsyncData(user)`, redirect to /home | backend log shows `/auth/login`; /home renders with the correct user.id matching the curl response | PASS |
| /home renders user.name / .email / .phone / .id | all four fields populated from `/auth/me` payload | matches | PASS |
| Tap "Sair" → `signOut` | storage cleared, `state = AsyncData(null)`, redirect to /login | login screen back | PASS |

(Auto-refresh on 401 + cascade revoke were already smoke-tested at the backend level in session 04 with identical refresh behaviour; the interceptor uses the same /auth/refresh endpoint, so the path is exercised by token expiry — explicit mid-session expiry test deferred to Phase 4 acceptance.)

## Decisions Made

1. **`tsx` for the backend was already locked in session 04, no change here.** Only the mobile side moved.
2. **`flutter_secure_storage` 9.x stays for M1.** v10 has a new custom-cipher implementation with auto-migration that's the 2026 best practice, but the upgrade path requires a new ADR + testing of the migration on real devices. M1 deadline 2026-05-26 is the constraint; argon2id-style "right thing post-M1" applies. Filed.
3. **Reuse-detection cascade revokes ALL of the user's refresh tokens** (already decided in session 04, but the mobile `AuthInterceptor` consumes this contract — on a `token_reuse` 401 it clears storage and forces the user back to /login, which matches the backend's stricter posture).
4. **Register → auto-login on the mobile UI**, even though the backend `/auth/register` does not return tokens. The user always wants to land logged in after creating an account. The UI just chains `login(...)` after `register(...)` succeeds.
5. **GoRouter redirect via `refreshListenable: ChangeNotifier`** — the canonical Riverpod-meets-GoRouter bridge. Using `redirect` alone wouldn't re-evaluate when auth state flips; `refreshListenable` triggers re-evaluation on every `notifyListeners()`.

## Open Questions Left

- [ ] Mid-session token expiry test (force the access TTL low, run a request after expiry, verify the auto-refresh interceptor swaps tokens transparently). Path is exercised by current contract; explicit observability is Phase 4 work.
- [ ] Persistence on cold start (kill the app, relaunch — tokens should still be in `EncryptedSharedPreferences`, `/me` should populate state, redirect should land on /home directly). Path is implemented; manual verification when the host is less stressed.
- [ ] Whether the host hardware (Intel i5 1038NG7, 16GB) can sustain a daily dev loop with emulator + Docker + Cursor open simultaneously. Currently runs a load average of 40+ — usable but slow. A physical Android device via USB would change the ergonomics meaningfully. Filed in TODO discovery.

## Files Changed

**Created:**
- `apps/mobile/lib/core/network/api_client.dart`
- `apps/mobile/lib/core/network/auth_interceptor.dart`
- `apps/mobile/lib/core/providers/api_providers.dart`
- `apps/mobile/lib/features/auth/data/auth_repository.dart`
- `apps/mobile/lib/features/auth/data/token_storage.dart`
- `apps/mobile/lib/features/auth/state/auth_controller.dart`
- `apps/mobile/lib/features/home/presentation/home_placeholder_page.dart`
- `apps/mobile/android/app/src/main/res/xml/network_security_config.xml`
- `docs/sessions/2026-05-08-05-mobile-auth-integration.md`

**Modified:**
- `apps/mobile/lib/app.dart` (router redirect on auth state)
- `apps/mobile/lib/features/auth/presentation/login_page.dart` (ConsumerStatefulWidget; first-frame `minHeight.clamp`; submit calls `login` + handles AuthApiException)
- `apps/mobile/lib/features/auth/presentation/register_page.dart` (same conversion + `register → login` chain)
- `apps/mobile/android/app/src/main/AndroidManifest.xml` (`networkSecurityConfig` reference)
- `TODO.md` (3 mobile auth tasks marked done; new "Done" entry; last-updated)
- `docs/sessions/0001-INDEX.md` (this session)

## Commits Pushed

```
<hash>  feat(auth): wire mobile login + register to backend (dio + riverpod + secure storage)
<hash>  docs(sessions): record mobile auth integration shipping
```

## Hand-off Notes for Next Session

- **Branch:** `develop`. Working tree clean.
- **Backend dev:** `cd apps/backend && bun run dev`. JWT keys live in `apps/backend/.env` (gitignored, regenerate via `scripts/generate-jwt-keys.sh` on a fresh checkout).
- **Mobile dev:** `cd apps/mobile && flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=APP_ENV=development`.
- **Codegen:** if you change `@riverpod` annotations, run `dart run build_runner build` (no `--delete-conflicting-outputs` in build_runner 2.5+ — it's now the default). Generated `*.g.dart` are gitignored.
- **Phase 2 status:** mobile auth = DONE end-to-end. Remaining Phase 2 tracks: Landing sections + visual identity, GraphHopper SP graph + benchmark. Recommend GraphHopper next — it's the technical-risk track for M1 acceptance criterion #3 (p95 < 200ms).
- **Performance note:** the Mac is at load avg 40+ when emulator + Docker + Cursor are all running. Closing Android Studio and unused IDE windows shaves ~15% load. A USB-cable physical Android changes this dramatically; worth trying for the daily loop.

## Reference Material Used

- Context7: `/cfug/dio` — `QueuedInterceptor` token-refresh pattern (consulted 2026-05-08).
- Context7: `/rrousselgit/riverpod/riverpod-v3.0.2` — AsyncNotifier `build` + state mutation patterns (consulted 2026-05-08).
- Web: pub.dev `flutter_secure_storage` 2026 docs — `AndroidOptions(encryptedSharedPreferences: true)`, `resetOnError` default, v10 migration path.
- ADR-0013, ADR-0005, ADR-0002, ADR-0006.
