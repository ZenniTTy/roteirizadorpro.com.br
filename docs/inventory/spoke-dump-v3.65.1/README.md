# Spoke static dump — v3.65.1

> **App:** Spoke / Circuit Route Planner (`com.underwood.route_optimiser`)
> **Version:** versionName `3.65.1` · versionCode `3650100` · minSdk 32 · targetSdk 36
> **Dumped:** 2026-06-09, from the licensed install on the Samsung M54 (`RQCW401G33T`)
> **Method:** `adb pull` (4 splits) → APKEditor merge → apktool (resources) + jadx (code)
> **Legal:** ADR-0010 Amendment 2 (inspection method is operator's choice) + ADR-0045. The shipped Roteirizador Pro product carries 100% original visual identity (ADR-0035). This dump is an internal engineering baseline for FUNCTIONAL parity — never a source of visual assets.

## What is committed here (light, versioned)

| File | What it is |
|---|---|
| `strings-pt-rBR.xml` | All 2.404 Brazilian-Portuguese UI texts, with their resource `name=` IDs. The frozen microcopy source-of-truth. |
| `strings-default.xml` | The 2.603 default (EN) strings — same resource names, useful when a PT-BR string is missing. |
| `AndroidManifest.xml` | Permissions, activities, the single-Activity Compose structure. |
| `ui-screen-tree.txt` | The full screen/navigation tree, derived from the `com.circuit.ui.*` package layout (the decompiled code). This is the map that runtime click-by-click used to discover. |
| `MASTER-TABLE.md` | **The deliverable.** string → resource → screen → data-model table for the 20 previously "Não drilled" screens. Turns inference into fact. |

## What is NOT committed (heavy, regenerable — lives at `~/spoke-dump`)

The merged APK (~106 MB), the 53.036 decompiled `.java` files (~587 MB), and binary drawables stay outside the repo (`.gitignore` blocks them). To regenerate from scratch (~10 min, device connected):

```bash
# 1. Pull all 4 splits (the loop avoids the CR line-ending gotcha)
mkdir -p ~/spoke-splits && cd ~/spoke-splits
adb shell pm path com.underwood.route_optimiser | sed 's/package://' | tr -d '\r' \
  | while read p; do adb pull "$p" .; done

# 2. Merge splits → standalone APK (APKEditor V1.4.9, ~/tools)
java -jar ~/tools/APKEditor-1.4.9.jar m -i ~/spoke-splits -o ~/spoke-merged.apk -f

# 3. Resources (apktool 3.0.2) — strings, manifest, drawables
apktool d ~/spoke-merged.apk -o ~/spoke-dump/res-decoded -s -f

# 4. Code (jadx 1.5.5) — DEX → readable Java, --deobf handles Pairip
jadx -j 4 --deobf --deobf-min 3 --show-bad-code -d ~/spoke-dump/jadx-out ~/spoke-merged.apk
```

## How to use the dump (the division of labour)

- **The dump answers "WHAT exists"** (frozen truth): exact PT-BR texts, which fields a screen has, defaults (08:00–15:00, 30 min), ranges/validations, picker option enums, the screen tree.
- **Runtime inspection answers "HOW it behaves"** (live truth): which screen a tap actually opens, back-stack order, sheet animations, post-optimization disabled states.
- **Order:** dump FIRST (builds the fact table + concrete hypotheses with exact text), runtime SECOND only to CONFIRM each row. You stop clicking screen-by-screen "to discover what's there" and start clicking once "to confirm what the dump already said." That inversion is what kills the recurring stale-baseline rework (ADR-0041/0042/0043/0044).

## Caveats (honest limits)

- **Compose, not Flutter/RN:** UI is in Kotlin/Compose bytecode (jadx), not `res/layout/*.xml`. Only Settings is a classic `PreferenceActivity` with extractable XML.
- **Pairip DRM** (`com.pairip.licensecheck`) wraps the DEX — some classes are obfuscated (`a/b/c`). The `com.circuit.ui.*` UX packages decompiled mostly LEGIBLE; strings always survive. Don't trust obfuscated class logic; trust strings + package names.
- **Version skew is the #1 risk:** this is a frozen snapshot of v3.65.1. If the live app updates, re-pull and bump the folder name. Every MASTER-TABLE row carries a `Precisa-runtime` field for what still needs a live confirm.
- **uiautomator is blind to Compose ImageVectors** — for icon presence, the dump (drawable/ImageVector in code) + a screenshot win, never the XML node tree.
