#!/usr/bin/env bash
set -euo pipefail

cd android
chmod +x ./gradlew
./gradlew clean bundleRelease --no-daemon --stacktrace
cd -
mkdir -p artifacts
cp -v android/app/build/outputs/bundle/release/*.aab artifacts/ || true