#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ANDROID_HOME:-}" ]]; then
  echo "ANDROID_HOME not set"
fi

./android/gradlew -v || true
node -v && yarn -v
