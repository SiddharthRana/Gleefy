#!/usr/bin/env bash
# Builds the Android release APKs locally (CI skips this to save build minutes) and checks each one
# against the 25 MB per-ABI budget. Debug-signed unless a release keystore is configured
# (apps/mobile/README.md). Usage: scripts/android-build.sh [extra flutter build args]
set -euo pipefail
cd "$(dirname "$0")/../apps/mobile"
flutter pub get
flutter analyze
flutter build apk --release --split-per-abi "$@"
status=0
for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
  size=$(wc -c <"$apk")
  printf '%-40s %6.1f MB\n' "$(basename "$apk")" "$(echo "$size / 1048576" | bc -l)"
  if [ "$size" -gt $((25 * 1024 * 1024)) ]; then
    echo "  over the 25 MB budget" >&2
    status=1
  fi
done
exit $status
