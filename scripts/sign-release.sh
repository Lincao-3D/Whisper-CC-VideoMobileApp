#!/usr/bin/env bash
set -euo pipefail

# Expect keystore mounted/copied at android/app/signing/release.keystore
KS_PATH="android/app/signing/release.keystore"
if [[ -f "$KS_PATH" ]]; then
  echo "Using release keystore at $KS_PATH"
else
  echo "No keystore found at $KS_PATH – continuing unsigned (CI can sign later)."
fi

# Append signing configs to gradle.properties if env vars exist
if [[ -n "${ANDROID_KEYSTORE_PASSWORD:-}" && -n "${ANDROID_KEY_ALIAS:-}" && -n "${ANDROID_KEY_PASSWORD:-}" ]]; then
  cat >> android/gradle.properties <<EOF
MYAPP_UPLOAD_STORE_FILE=signing/release.keystore
MYAPP_UPLOAD_STORE_PASSWORD=${ANDROID_KEYSTORE_PASSWORD}
MYAPP_UPLOAD_KEY_ALIAS=${ANDROID_KEY_ALIAS}
MYAPP_UPLOAD_KEY_PASSWORD=${ANDROID_KEY_PASSWORD}
EOF
fi