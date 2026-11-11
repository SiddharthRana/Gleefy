#!/usr/bin/env bash
# Builds the signed Android App Bundle (.aab) for Google Play, by hand (the very first upload has
# to be manual; later releases come from CI). Refuses to build without the upload key, because a
# debug-signed bundle is rejected by Play.
#   scripts/android-bundle.sh BUILD_NUMBER [extra flutter build args]
# Example: scripts/android-bundle.sh 1
set -euo pipefail
cd "$(dirname "$0")/../apps/mobile"
build="${1:?Give the build number (1 for the first upload, then one higher every time)}"
shift
if [ ! -f android/key.properties ]; then
  echo "android/key.properties is missing: create the upload key first (docs/launch/runbook.md, 3a)." >&2
  exit 1
fi
store=$(sed -n 's/^storeFile=//p' android/key.properties)
if [ ! -f "$store" ]; then
  echo "The keystore in android/key.properties isn't there: $store" >&2
  exit 1
fi
flutter pub get
flutter build appbundle --release --build-number="$build" \
  --dart-define=SITE_URL=https://gleefy.party "$@"
aab=build/app/outputs/bundle/release/app-release.aab
# Make sure it really is signed with the upload key, not the debug key.
if jarsigner -verify -verbose:summary "$aab" 2>/dev/null | grep -q "CN=Android Debug"; then
  echo "The bundle is debug-signed: check android/key.properties." >&2
  exit 1
fi
printf 'Built %s (%.1f MB), build %s\n' "$aab" "$(echo "$(wc -c <"$aab") / 1048576" | bc -l)" "$build"
