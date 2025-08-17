#!/usr/bin/env bash
set -euo pipefail
cd android
chmod +x ./gradlew
./gradlew assembleRelease --no-daemon --stacktrace
cd -
mkdir -p artifacts
cp -v android/app/build/outputs/apk/release/*.apk artifacts/ || true