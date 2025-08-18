#!/usr/bin/env bash
set -euo pipefail

# Move into the Android project folder
cd android

# Ensure Gradle wrapper is executable
chmod +x ./gradlew

# Build the release APK
./gradlew assembleRelease --no-daemon --stacktrace

# Go back to project root
cd -

# Create artifacts directory if needed
mkdir -p artifacts

# Copy generated APK(s) into artifacts folder
cp -v android/app/build/outputs/apk/release/*.apk artifacts/ || true
