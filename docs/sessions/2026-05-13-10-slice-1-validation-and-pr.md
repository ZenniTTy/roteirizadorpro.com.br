# Session 2026-05-13-10 — slice-1-validation-and-pr

## Metadata

- **Date**: 2026-05-13 (America/Sao_Paulo)
- **Sequence**: 10
- **Agent**: Claude Code (Opus 4.7, 1M ctx)
- **Human**: Eduardo
- **Topic**: Slice 1 validation on a real device, INTERNET-permission fix, PR open
- **Duration**: ~2h (rolled directly from session 09; this log captures the work after the 09 commit landed)
- **Related ADRs**: ADR-0014 (updated this session with the "Sharp edges learned during slice 1" subsection)
- **Related TODO items**: M2 slice 1 — device validation, INTERNET fix, PR.

## Goal of the Session

Session 09 left slice 1 with all code in place, four conventional commits on
`feat/m2-slice-1-apk`, the branch pushed to origin, but two open todos:
(a) install the published APK on a real Android device and exercise the
register/login flow against `https://api.roteirizadorpro.com.br`,
(b) open the PR with the validation evidence and confirm the Vercel preview
deploy serves the APK correctly. This session does that, plus the
INTERNET-permission fix that surfaced during validation.

## What Was Done

### USB debugging walkthrough + first install

Eduardo had never enabled USB debugging on Android before. Walked through the
seven-tap-on-Build-number → Developer options → USB debugging route and the
first-time "Allow USB debugging from this computer?" prompt on the device.
`adb devices -l` confirmed a Samsung Galaxy A06 (model `SM-A065M`, serial
`R9QY30134RD`, transport_id 1) attached and authorized. `adb install -r
apps/landing/public/roteirizador-pro-v1.0.0.apk` → `Success`. App appeared on
the launcher with the new "Roteirizador Pro" label (the manifest fix from
session 09 worked).

### Symptom — `Failed host lookup` on every request

The app rendered the Register screen 1:1 with the prototype. Filled the form
(Eduardo Ianelli, teste@ianelli.tech, +55 16988403285, 8-char password) and
tapped Criar conta. Bottom toast: `The connection errored: Failed host
lookup: 'api.roteirizadorpro.com.br' This indicates an error which most
likely cannot be solved by the library.` Reproduced on both Wi-Fi
("ELOVISIONDIGITAL.COM") and LTE.

### Diagnosis ladder

1. **DNS propagation check.** `dig +short api.roteirizadorpro.com.br
   @8.8.8.8 / @1.1.1.1 / @181.213.132.2 (Vivo) / Google DoH` — all returned
   `138.197.38.243`. Apex resolves to Vercel (`64.29.17.x`). Not a
   propagation issue; the registration is on Vercel DNS with TTL 60 and is
   globally propagated.
2. **Device-level reachability.** `adb shell ping -c 3 8.8.8.8` returned
   ~40 ms RTT — internet is fine. `adb shell ping -c 1
   api.roteirizadorpro.com.br` returned `64 bytes from 138.197.38.243:
   icmp_seq=1 ttl=52 time=220 ms`. The **system resolver inside the device**
   resolves the host. So it's not a DNS-of-the-network issue either.
3. **Network type / DNS provider.** `dumpsys connectivity` showed Wi-Fi
   DNS set to the ISP (`181.213.132.2/3` IPv4 + `2804:14d:1::181:213:132:2/3`
   IPv6), LTE on Vivo. Both networks resolve the host correctly from the
   shell.
4. **Cleartext / network-security-config.** Read
   `apps/mobile/android/app/src/main/res/xml/network_security_config.xml` —
   cleartext exception scoped to `10.0.2.2`, `127.0.0.1`, `localhost` only.
   Production goes over HTTPS, which is permitted by default. Not it.
5. **Negative DNS cache inside the Dart VM.** `adb shell am force-stop
   br.com.roteirizadorpro.roteirizador_pro` to flush the process, reopened
   the app. Same error. Ruled out.
6. **Permission audit.** Switched to `aapt2 dump permissions <published
   APK>`. Output:

   ```
   package: br.com.roteirizadorpro.roteirizador_pro
   permission: br.com.roteirizadorpro.roteirizador_pro.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
   uses-permission: name='br.com.roteirizadorpro.roteirizador_pro.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
   ```

   **No `android.permission.INTERNET`.** Cross-referenced with
   `apps/mobile/android/app/src/{debug,profile}/AndroidManifest.xml` — both
   declare INTERNET. `src/main/AndroidManifest.xml` — **does not.** Context7
   (`/websites/flutter_dev`) confirmed: `flutter create` only scaffolds the
   INTERNET permission in the debug/profile overlays (those modes need it
   for hot-reload). Release builds don't merge those overlays. Smoking gun
   found.

### Fix

Added `<uses-permission android:name="android.permission.INTERNET" />` to
`apps/mobile/android/app/src/main/AndroidManifest.xml` with an explanatory
comment ("Release builds do NOT merge those overlays, so the main manifest
must declare it explicitly."). Re-ran `bash scripts/build-release-apk.sh` →
new 34 MB universal APK in `~144 s`. `aapt2 dump permissions` on the rebuilt
APK now reports `uses-permission: name='android.permission.INTERNET'` —
confirmed.

Copied the rebuilt APK to `apps/landing/public/roteirizador-pro-v1.0.0.apk`
and ran `adb install -r` to overwrite the device's prior install. Eduardo
re-entered the form data and tapped Criar conta — landed on `/home` with the
`/auth/me` payload. Tapped Sair, landed on `/login`, signed back in with the
same credentials, round-trip green.

### Documentation of the fix

- Committed `fix(mobile): declare android.permission.internet in release
  manifest` (commit `afbd999`) — the manifest change + the rebuilt APK
  binary.
- Updated `docs/sessions/2026-05-13-09-m2-slice-1-apk.md` with a "Physical-device
  validation — INTERNET permission gotcha" subsection narrating the diagnosis
  ladder.
- Extended ADR-0014 with a "Sharp edges learned during slice 1" section so
  the rule lives where future contributors will look.
- Marked the validation TODO done in `TODO.md` and inserted a sub-item
  describing the fix.
- Wrote a project-scoped memory entry at
  `~/.claude/projects/.../memory/flutter-android-release-internet-permission.md`
  (feedback type) so a future agent will pre-check `aapt2 dump permissions`
  before chasing DNS rabbit holes again. Added the entry to `MEMORY.md`.
- Committed `docs: capture internet-permission gotcha in slice 1 record`
  (commit `8e48c57`).

### Push + PR

`git push origin feat/m2-slice-1-apk` pushed both new commits.

Opened **PR #3** (`feat(m2-slice-1): distributable Android APK + landing CTAs wired`)
via `gh pr create --base develop --head feat/m2-slice-1-apk`. PR body covers:

- Summary of the six commits in the slice.
- Test plan checklist (analyze/typecheck/lint, apksigner verify, aapt2 dump
  permissions, adb install on Galaxy A06, register/login round-trip).
- Manual action required before merge: 1Password backup of the keystore +
  `.env.deploy` block.
- Cross-references ADR-0014, session log, and the memory entry.

URL: https://github.com/ZenniTTy/roteirizadorpro.com.br/pull/3.

### Vercel preview verification

PR status check `Vercel` reports `SUCCESS` (deployment ready). Preview URL:
`https://roteirizadorpro-com-br-git-feat-m2-slice-1-apk-roteirizador-pro.vercel.app`.

`curl -sI` on `/roteirizador-pro-v1.0.0.apk` returned HTTP 401 — expected:
the Vercel project has **Deployment Protection** enabled, so every preview
URL is gated by Vercel SSO. The 401 means the file exists and routing works;
just authenticated. Production
(`https://roteirizadorpro.com.br/roteirizador-pro-v1.0.0.apk`) returns
307 → www → 404 as expected — the APK only lands in prod after PR #3 merges.

## Decisions Made

1. **Treat the INTERNET-permission omission as a documented sharp edge, not
   a stack change.** It's a `flutter create` scaffolding gotcha, not a stack
   choice. Lives as a follow-up subsection inside ADR-0014 plus a feedback
   memory entry — no new ADR.
2. **Open the PR rather than wait for the 1Password backup.** The backup is
   a *pre-merge* requirement, not a pre-PR one. PR is the canvas where the
   reviewer (Eduardo) is reminded of the backup step. Recorded in the PR
   body under "Manual action required before merge."
3. **Vercel SSO preview 401 is not a regression.** Deployment Protection is
   the default on Vercel for non-public projects; the 401 confirms the file
   is in the build output and proves the routing works. Real validation
   happens once the APK reaches the apex on merge.

## Open Questions Left

- [ ] **1Password backup of the keystore.** Pre-merge requirement. Eduardo
  to export `~/.android-keystores/roteirizador-pro.jks` and the
  `ANDROID_KEYSTORE_*` block from `.env.deploy` to a 1Password item before
  merging PR #3. Without this, the M2-onwards update channel is one laptop
  failure away from being unrecoverable.
- [ ] **Merge PR #3.** Pending Eduardo's review and the 1Password backup.
- [ ] **Tag `v1.0.0` after merge.** The semver matches `pubspec.yaml`.
- [ ] **Validate APK download on production (apex)** once merged: `curl -sI
  https://roteirizadorpro.com.br/roteirizador-pro-v1.0.0.apk` should return
  HTTP 200 with `Content-Type: application/vnd.android.package-archive`,
  and the four CTA links on `https://roteirizadorpro.com.br` should trigger
  a download.
- [ ] **Slice 2 — Telas Core** is the next planning conversation: ~15 screens
  remaining in `prototipo/screens-{a,b,d,e}.jsx`. Use
  `superpowers:brainstorming` before any code.

## Files Changed

**Created:**

- `docs/sessions/2026-05-13-10-slice-1-validation-and-pr.md` (this file).
- `~/.claude/projects/.../memory/flutter-android-release-internet-permission.md`
  (project-scoped feedback memory; outside the repo).
- `~/.claude/projects/.../memory/MEMORY.md` (the memory index, outside the
  repo).

**Modified:**

- `apps/mobile/android/app/src/main/AndroidManifest.xml` — added the
  INTERNET permission with an explanatory comment.
- `apps/landing/public/roteirizador-pro-v1.0.0.apk` — rebuilt and replaced.
- `docs/decisions/0014-android-release-signing.md` — appended "Sharp edges
  learned during slice 1" subsection.
- `docs/sessions/2026-05-13-09-m2-slice-1-apk.md` — appended "Physical-device
  validation — INTERNET permission gotcha" subsection + updated hand-off
  notes.
- `TODO.md` — marked device-validation done with a sub-item explaining the
  INTERNET fix.
- `docs/sessions/0001-INDEX.md` — this session entry (added by the
  session-end commit at the end).

## Commits Pushed

```
afbd999 fix(mobile): declare android.permission.internet in release manifest
8e48c57 docs: capture internet-permission gotcha in slice 1 record
```

PR #3 currently sits at six commits cumulative over sessions 09 + 10
(`e92e19d`, `4fe22a5`, `f6aafcf`, `3df0df1`, `afbd999`, `8e48c57`). A seventh
commit lands as the session-end commit for this log.

## Hand-off Notes for Next Session

- **Branch:** `feat/m2-slice-1-apk` (off `develop`), pushed to origin, PR #3
  open.
- **Working tree:** will be clean once the session-end commit (this file +
  TODO + index) lands.
- **PR status:** Vercel preview SUCCESS, no review yet, no merge yet.
  Eduardo decides when to merge. Before merging, **export the keystore to
  1Password** — this is the one thing this session could not automate.
- **Post-merge sequence:** (1) verify
  `https://roteirizadorpro.com.br/roteirizador-pro-v1.0.0.apk` returns 200,
  (2) sideload-test from a browser → "Baixar app" on the live landing,
  (3) `git tag -a v1.0.0 -m "M2 slice 1 — distributable APK"` and `git push
  origin v1.0.0`, (4) close slice 1 in `TODO.md`.
- **Slice 2 kickoff:** when you're ready, read `prototipo/screens-a.jsx`
  through `screens-e.jsx` (you'll find ~15 screen functions across them),
  start with `ScreenHomeEmpty` + `ScreenHomeList` since they unlock every
  subsequent screen. Use `superpowers:brainstorming` before any code.
- **The new memory entry will fire** on any future Flutter Android release
  work — the next agent will see `MEMORY.md` at conversation start and
  pre-check `aapt2 dump permissions` instead of chasing DNS.

## Reference Material Used

- Context7: `/websites/flutter_dev` queried 2026-05-13 — confirmed
  "Configure Android Internet permission" snippet, "Android App Manifest
  Configuration" default structure, "Enable Network Access for Android",
  "Networking > Platform notes > Android" guidance. All four converge on:
  declare `android.permission.INTERNET` in
  `[project]/android/app/src/main/AndroidManifest.xml`.
- `adb` / `apksigner` / `aapt2` from the Android SDK 36.1.0 + Build Tools
  37.0.0.
- `dig`, `curl`, the GitHub `gh` CLI.
- Existing project: ADR-0014 (slice 1 ADR), session log
  `2026-05-13-09-m2-slice-1-apk.md`,
  `apps/mobile/android/app/src/{debug,profile,main}/AndroidManifest.xml`,
  `apps/mobile/android/app/src/main/res/xml/network_security_config.xml`.
