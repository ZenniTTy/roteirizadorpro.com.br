#!/usr/bin/env bash
# Builds a signed, production-targeted Android APK for distribution from the
# landing page. Requires apps/mobile/android/key.properties (see ADR-0014) and a
# Flutter SDK with the Android toolchain installed (`flutter doctor`).
#
# Output: build/app/outputs/flutter-apk/app-release.apk (universal: arm + arm64).
# Publishing: cp this APK to apps/landing/public/roteirizador-pro-<version>.apk.

set -euo pipefail

cd "$(dirname "$0")/.."

API_BASE_URL="${API_BASE_URL:-https://api.roteirizadorpro.com.br}"
APP_ENV="${APP_ENV:-production}"

echo "==> Cleaning previous build outputs"
flutter clean

echo "==> Fetching pubspec deps"
flutter pub get

echo "==> Building release APK (universal: arm + arm64)"
echo "    API_BASE_URL = $API_BASE_URL"
echo "    APP_ENV      = $APP_ENV"

# A single APK targeting both arm and arm64 keeps distribution simple — one
# link on the landing page works for every Android user. ~34 MB total; well
# under Vercel's 100 MB asset limit. Add --split-per-abi later if size matters.
flutter build apk \
  --release \
  --target-platform=android-arm,android-arm64 \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=APP_ENV="$APP_ENV"

echo "==> Build artifact"
ls -lh build/app/outputs/flutter-apk/app-release.apk
