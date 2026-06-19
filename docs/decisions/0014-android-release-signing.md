# ADR-0014: Android Release Signing and APK Distribution via the Landing Page

- **Status:** Accepted
- **Date:** 2026-05-13
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0002 (Flutter Mobile)

## Context

M2 slice 1 — the first user-visible deliverable of M2 — is making the app actually
installable. M1 shipped only an unsigned debug build of the Login + Register screens,
runnable in an emulator on the developer machine. To convert the landing page's
"Baixar app" CTA into a working download and to let real motoboys test the app, we
need:

1. **A persistent app identity.** Android signs every APK with a private key whose
   public certificate becomes the *de facto* package identity. The certificate
   used on the first release is the only one that can sign every subsequent
   update — losing it means every existing user has to uninstall and reinstall
   to receive any future version. The keypair must survive the project well past
   the M2 window, and it has to be backed up off-machine because the laptop is
   the only working copy.
2. **A signed APK.** Release builds with the default `flutter create` Gradle
   template still fall back to the debug signing config (Google's `debug.keystore`
   on the laptop), which is fine for `flutter run --release` but not for any APK
   that leaves the developer's machine — Android refuses to upgrade a release
   APK signed with a different key, and side-loaded debug-signed builds throw
   warnings about an unverified source.
3. **A distribution channel.** We are not going through the Play Store on M2 (no
   budget for Play Console + review back-and-forth). The landing page is the only
   surface the client uses to acquire users, so the APK has to be served from
   `roteirizadorpro.com.br` with a one-click experience that matches the rest
   of the prototype's UX.

Three sub-decisions follow from this.

## Options Considered

### Keystore custody

#### Option A — Generate locally + store on the developer machine outside the repo (this ADR)

- **Pros:** zero external dependency; works today; the developer (Eduardo) is the
  one publishing releases anyway, so the chain of custody is straightforward;
  `.env.deploy` already holds other deploy secrets (DO token, Postgres password,
  JWT keys) under the same gitignored umbrella — keystore credentials fit the
  existing pattern.
- **Cons:** if the laptop dies and the 1Password backup also fails, the key is
  gone forever. Mitigated by mandating a 1Password backup of *both* the `.jks`
  file *and* the credentials before slice 1 merges to `develop`.

#### Option B — Client (account holder) generates and ships the keystore

- **Pros:** the client owns their app identity from day one, mirroring the
  pattern used for the DO account ownership.
- **Cons:** the client is not technical; `keytool` is the worst possible first
  encounter with the toolchain (interactive prompts in mixed pt-BR/EN, error
  messages about cipher providers). Risk of a weak passphrase or a lost file
  during the M2 window is real and blocks slice 1.

#### Option C — Google Play App Signing

- **Pros:** Google holds the actual signing key in a hardware-isolated key
  manager; we only handle an upload key. Industry-standard for Play Store apps.
- **Cons:** requires the app to be enrolled in Play App Signing, which requires
  a Play Console account, which requires uploading the app to Play, which is
  outside M2's scope. Adds Play Store as a parallel distribution channel rather
  than replacing direct APK distribution.

### Distribution channel

#### Option α — Host the APK in `apps/landing/public/` and serve via Vercel (this ADR)

- **Pros:** zero new infrastructure; landing already deploys via Vercel; one
  unified `git push` ships both code and binary; Vercel's static serving sets
  `Content-Type: application/vnd.android.package-archive` automatically when
  the file extension is `.apk`; per-file limit on Vercel's CDN is 100 MB, and
  the current universal APK is 34 MB.
- **Cons:** every APK version is committed to git; a 34 MB binary in the repo
  is large but tolerable at the M2 cadence of one release per slice; needs a
  `.gitignore` exception (`!apps/landing/public/*.apk`) because the project's
  global `*.apk` rule otherwise hides it.

#### Option β — Vercel Blob Storage (binary lives outside the repo)

- **Pros:** repo stays free of binaries; Vercel Blob is pay-per-use and the
  cost for one ~34 MB binary downloaded a few thousand times a month is sub-R$ 1.
- **Cons:** introduces a separate service to manage (blob keys, upload step
  in CI, env var to point the landing at the latest blob URL); release flow
  becomes "build APK → `vercel blob put` → update env var → redeploy" instead
  of "build APK → commit → push." More moving parts for marginal repo cleanliness.

#### Option γ — GitHub Releases as the distribution surface

- **Pros:** the binary lives in a release asset, not in git LFS or in the repo.
- **Cons:** the repo is private; making releases public means making the
  release assets public *but not the repo*, which GitHub permits but creates
  a confusing access surface; the URL is GitHub-flavored rather than
  `roteirizadorpro.com.br`-flavored.

### Build configuration

#### Option δ — `--split-per-abi`: one APK per ABI

- **Pros:** smaller individual files (16 MB armeabi-v7a, 19 MB arm64-v8a);
  follows Google's recommendation for Play Store.
- **Cons:** two binaries to publish, two links to maintain, user-facing routing
  ("which Android do I have?") that motoboys do not want to think about; a
  user on the wrong ABI sees "App not installed" with no useful explanation.

#### Option ε — Single universal APK (this ADR)

- **Pros:** one link, one binary, zero user-facing complexity. 34 MB is
  ~10% above the smallest split but objectively small for a 2026 Android app
  (the median modern app installed APK is 60+ MB).
- **Cons:** users with 32-bit devices download a few MB of arm64 code they will
  never execute. Marginal in 2026.

## Decision

1. **Keystore custody:** Option A. Generate the keystore locally, store at
   `~/.android-keystores/roteirizador-pro.jks` with `chmod 600`, persist its
   credentials in `.env.deploy` (already gitignored via the `.env.*` umbrella),
   and back up *both* the `.jks` file and the credentials in 1Password before
   slice 1 merges.

2. **Distribution channel:** Option α. Commit the APK under
   `apps/landing/public/roteirizador-pro-v<semver>.apk`, with a `.gitignore`
   exception scoped exactly to that directory so the global `*.apk` rule still
   blocks every other accidental APK commit. Each release ships in one PR
   alongside the matching source.

3. **Build configuration:** Option ε. Build a single universal APK (`arm` + `arm64`)
   via `flutter build apk --release --target-platform=android-arm,android-arm64`.

The signing happens through the standard `key.properties` pattern from the
official Flutter docs (`docs.flutter.dev/deployment/android`):

- `apps/mobile/android/key.properties` is gitignored (already in the
  `flutter create` template at line 12 of `apps/mobile/android/.gitignore`) and
  holds `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
- `apps/mobile/android/app/build.gradle.kts` reads `key.properties` at
  configuration time and, if present, plugs it into a `release` signing config.
  If `key.properties` is *absent* (CI without secrets, fresh clone), the release
  build falls back to the debug signing config so `flutter build` keeps working
  for non-publishing purposes.
- `apps/mobile/scripts/build-release-apk.sh` encapsulates the full build command
  with the production `--dart-define`s baked in, so the publisher does not have
  to remember the flags.

## Consequences

- **Positive:** the app has a stable cryptographic identity that survives the
  M2 window and every future M3+ release; the developer workflow is one
  command (`bash scripts/build-release-apk.sh`); the distribution channel uses
  infrastructure that already exists; the landing page CTA goes from a placeholder
  `href="#"` to a real downloadable artifact; the build script and gradle config
  are robust to running on CI (which has no `key.properties` and falls back to
  debug signing).
- **Negative:** the repo carries a ~34 MB binary that ships in every clone; if
  the keystore or the 1Password backup is ever lost, the app's update channel
  is permanently broken (every user has to uninstall and reinstall to receive
  a new version signed with a different key); release versioning is manual
  (no CI automation in M2 — the publisher edits `pubspec.yaml`, copies the APK,
  renames the file, commits).
- **Neutral:** moving to Play Store later (M3?) is unblocked because Play App
  Signing can re-enroll any existing key; the universal APK can be swapped for
  per-ABI splits with one flag change to the build script.

## Implementation Notes

### Keystore details (as generated 2026-05-13)

| Field | Value |
|---|---|
| File | `~/.android-keystores/roteirizador-pro.jks` |
| Storetype | PKCS12 |
| Key alias | `roteirizador-pro` |
| Key algorithm | RSA |
| Key size | 4096 bits |
| Validity | 2026-05-13 → 2056-05-05 (30 years) |
| Distinguished Name | `CN=Roteirizador Pro, OU=Mobile, O=Elo Vision Digital, L=Sao Paulo, ST=SP, C=BR` |
| Certificate SHA-256 | `D9:C9:61:D6:A3:2A:0C:45:B6:11:E0:E1:2D:86:FA:7E:52:1C:D3:3C:88:83:3C:7C:5D:5A:B9:91:9F:E9:14:31` |
| Certificate SHA-1 | `FD:FD:56:73:BE:7B:BA:47:53:BE:B1:51:15:05:FC:DA:F6:BB:2D:63` |
| Storepass | in `.env.deploy` as `ANDROID_KEYSTORE_STORE_PASSWORD` |
| Keypass | same as storepass (PKCS12 forces a single password) |

Note: PKCS12 keystores in Java do not support distinct store and key passwords —
`keytool -genkeypair` silently ignores `-keypass` and reuses `-storepass` for
both. The one-password property is recorded in `.env.deploy` and is not a
weakness against our threat model (an attacker who has the storepass already
has the key).

### key.properties layout

```properties
storePassword=<from .env.deploy ANDROID_KEYSTORE_STORE_PASSWORD>
keyPassword=<same as storePassword for PKCS12>
keyAlias=roteirizador-pro
storeFile=/Users/eduardorodrigues/.android-keystores/roteirizador-pro.jks
```

### Versioning convention

`apps/mobile/pubspec.yaml` `version:` follows `<major>.<minor>.<patch>+<build>`.
`<major>.<minor>.<patch>` is `versionName` (display); `<build>` is `versionCode`
(integer, monotonic — Android refuses upgrades to a lower or equal `versionCode`).
Every published APK bumps `<build>` even when `<major>.<minor>.<patch>` is unchanged.
Slice 1 ships as `1.0.0+1`.

### File naming convention for the published APK

`apps/landing/public/roteirizador-pro-v<major>.<minor>.<patch>.apk`. Build-suffix
information is intentionally omitted from the filename so the URL on the landing
is stable when the publisher republishes the same semver with a higher build code
(e.g., a hotfix). The version inside the APK is the source of truth via
`PackageManager.getPackageInfo().versionName` / `versionCode`.

### What this ADR rejects

- Committing the keystore `.jks` file to the repository.
- Publishing an APK signed with the debug keystore (the Google-shipped default
  on `~/.android/debug.keystore`).
- Distributing the APK over plain HTTP, or from anywhere that is not the
  apex domain Vercel already serves.
- Adding any new infrastructure (Vercel Blob, GitHub Releases, S3) for the M2
  distribution channel.

### Follow-ups (post-merge)

- **1Password backup of keystore.** *Manual, by Eduardo, before this slice's PR
  is merged.* Without this, this whole ADR is unsafe.
- **Add APK signature scheme v1.** Android < 7.0 verifies APKs only via the
  v1 JAR scheme; v2-only signatures fail to install on 5.x/6.x devices. We
  currently ship v2-only. Add `--app-signature-schemes v1,v2,v3` to the
  signingConfig once we know whether any motoboy in the cohort runs Android < 7.
  Not in scope for slice 1 because the cohort is the developer's own device set.
- **Move from APK to AAB once Play Store enters the picture.** AAB is required
  for new Play Store submissions and lets the store generate per-device APKs
  from a single upload, eliminating the universal-vs-split tradeoff entirely.
  Not relevant for direct-download distribution.

### Sharp edges learned during slice 1

- **`android.permission.INTERNET` MUST be declared in
  `src/main/AndroidManifest.xml`.** `flutter create` scaffolds this permission
  only into the `src/debug/` and `src/profile/` manifest overlays, since those
  are the only modes that need the hot-reload wire. **Release builds do not
  merge those overlays.** Symptom of forgetting: every outbound socket fails
  with `Failed host lookup`, which is easy to misread as DNS. Diagnose with
  `aapt2 dump permissions <apk>` — if the only `uses-permission` is the
  `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` boilerplate, the INTERNET grant
  is missing. Recorded as a sanity-check step in `apps/mobile/scripts/build-release-apk.sh`
  follow-up: a future enhancement to the script can grep the merged manifest
  after build and abort if `INTERNET` is not present.

## References

- Flutter — *Build and release an Android app* — `https://docs.flutter.dev/deployment/android`.
- Context7: `/websites/flutter_dev` queried 2026-05-13 — Configure signing config
  in Gradle (Kotlin DSL) snippets.
- Android Developers — *APK Signature Scheme v2* — `https://source.android.com/docs/security/features/apksigning/v2`.
- ADR-0002 (Flutter as mobile framework).
