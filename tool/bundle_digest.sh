#!/usr/bin/env bash
# The identity of one CI artifact bundle: sha256 of the sorted
# `sha256  ./path` list of every file under DIR (hidden files included).
# ci.yml records it in candidate.json; promote.yml recomputes it from the
# downloaded artifact, so a changed, missing or extra file is a mismatch.
# Usage: tool/bundle_digest.sh DIR
set -euo pipefail
dir=${1:?usage: bundle_digest.sh DIR}
[ -d "$dir" ] || { echo "bundle_digest: $dir is not a directory" >&2; exit 1; }
cd "$dir"
find . -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum | sha256sum | cut -d' ' -f1
