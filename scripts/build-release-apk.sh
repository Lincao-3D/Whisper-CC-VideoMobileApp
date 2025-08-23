#!/usr/bin/env bash
set -euo pipefail

# Determine project root based on script location
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
ARTIFACTS_DIR="$ROOT_DIR/artifacts"

echo "==> Building Release APK in: $ANDROID_DIR"

# Ensure Gradle wrapper is executable
chmod +x "$ANDROID_DIR/gradlew"

# Run Gradle build
pushd "$ANDROID_DIR" >/dev/null
./gradlew assembleRelease --no-daemon --stacktrace --info
popd >/dev/null

# Prepare artifacts directory
mkdir -p "$ARTIFACTS_DIR"

# Copy APKs
echo "==> Copying APKs to: $ARTIFACTS_DIR"
find "$ANDROID_DIR/app/build/outputs/apk/release" -type f -name "*.apk" -exec cp -v {} "$ARTIFACTS_DIR/" \; || {
    echo "No APKs found — check Gradle output for issues."
}

echo "✅ APK build script completed."


#old #!/usr/bin/env bash
# set -euo pipefail

# # REMOVED - Controlled in Dockerfile -Move into the Android project folder
# # cd android

# # Ensure Gradle wrapper is executable
# chmod +x ./gradlew

# # Build the release APK
# ./gradlew assembleRelease --no-daemon --stacktrace

# # Go back to project root
# cd -

# # Create artifacts directory if needed
# mkdir -p artifacts

# # Copy generated APK(s) into artifacts folder
# cp -v android/app/build/outputs/apk/release/*.apk artifacts/ || true
