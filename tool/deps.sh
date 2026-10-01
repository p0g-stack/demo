#!/usr/bin/env bash
# squadron_process needs a patched Squadron until its channel-factory patch is
# upstream. Resolve once against stock Squadron, materialize the patched tree
# (written to pubspec_overrides.yaml, not committed), then resolve again.
# Run before tool/bootstrap.sh.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
dart run squadron_process:squadron_patch
flutter pub get
