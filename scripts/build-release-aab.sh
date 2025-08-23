#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

pushd "$ROOT/android" >/dev/null
chmod +x ./gradlew
./gradlew bundleRelease --no-daemon --stacktrace --info
popd >/dev/null

mkdir -p "$ROOT/artifacts"
cp -v "$ROOT/android/app/build/outputs/bundle/release/"*.aab "$ROOT/artifacts/" || true

#old #!/usr/bin/env bash
# set -euo pipefail

# # REMOVED - Controlled in Dockerfile -
# # cd android
# chmod +x ./gradlew
# ./gradlew bundleRelease --no-daemon --stacktrace
# cd -
# mkdir -p artifacts
# cp -v android/app/build/outputs/bundle/release/*.aab artifacts/ || true