#!/usr/bin/env sh
# Fetches squadron_process at the pinned commit into .deps/ and builds its
# patched Squadron (channel-factory patch). pubspec_overrides.yaml points pub
# at both. Run once before `flutter pub get`, and again when SQUADRON_PROCESS
# changes. Goes away once flutter_p0g applies the Squadron patch itself.
set -eu
SQUADRON_PROCESS=b4a599c2bca574d040df1d6404553672d3f15f28

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dir="$root/.deps/squadron_process"
if [ ! -d "$dir/.git" ]; then
  git init -q "$dir"
  git -C "$dir" remote add origin https://github.com/p0g-stack/squadron_process
fi
git -C "$dir" fetch -q --depth 1 origin "$SQUADRON_PROCESS"
git -C "$dir" checkout -q --force --detach "$SQUADRON_PROCESS"
"$dir/tool/squadron.sh" --no-override
