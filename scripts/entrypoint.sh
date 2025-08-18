#!/usr/bin/env bash
set -euo pipefail

# Pre‑build environment and signing
bash scripts/verify-env.sh || true
bash scripts/sign-release.sh || true

# Build artifacts
bash scripts/build-release-aab.sh
bash scripts/build-release-apk.sh

echo "🔍 Running post-build checks..."

# 1️⃣ Find whisper.so in any jniLibs/<ABI>/ directory
if find android/app/build -type f -path "*/jniLibs/*/whisper.so" | grep -q "whisper.so"; then
    echo "✅ Found whisper.so in jniLibs/"
else
    echo "❌ whisper.so not found in jniLibs/"
    exit 1
fi

# 2️⃣ Ensure fonts are bundled in APK assets
APK_PATH=$(find android/app/build/outputs/apk -type f -name "*.apk" | head -n 1)
if [ -z "$APK_PATH" ]; then
    echo "❌ No APK found to inspect."
    exit 1
fi

echo "Inspecting APK: $APK_PATH"
if unzip -l "$APK_PATH" | grep -q "assets/fonts/"; then
    echo "✅ Fonts directory found in APK assets."
else
    echo "❌ Fonts directory not found in APK assets."
    exit 1
fi

echo "🎯 All checks passed."
