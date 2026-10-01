#!/usr/bin/env bash
# Regenerates the workspace from the p0g_app brick and diffs it against this
# repo. Every generated file must match (after the same `dart format` the
# brick's bootstrap runs), except those listed in tool/regen.allow with a
# reason. Files the demo adds are free under app/lib/pages/, app/test/, core/,
# cli/lib/src/commands/ and tool/. Needs mason (mason_cli 0.1.4) and dart.
set -euo pipefail
BRICKS_REF=2ac3ac219fcf7f845b90f4c96006e2e46aa0e60f

root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cat > "$work/mason.yaml" <<YAML
bricks:
  p0g_app:
    git:
      url: https://github.com/p0g-stack/bricks
      path: bricks/p0g_app
      ref: $BRICKS_REF
YAML
(cd "$work" && mason get >/dev/null &&
  mason make p0g_app -c "$root/tool/p0g_app.json" -o "$work/out" \
    --on-conflict overwrite >/dev/null)
gen="$work/out/demo"
# Only what the brick stamps, not what pub get adds.
find "$gen" -type f | sort > "$work/files"
# Format needs the package graph; the stock Squadron is enough for that.
(cd "$gen" && flutter pub get >/dev/null 2>&1 && dart format core cli app/lib app/test >/dev/null 2>&1)

allowed() { grep -qxF "$1" <(sed -e 's/[[:space:]]*#.*$//' -e '/^$/d' "$root/tool/regen.allow"); }

fail=0
while IFS= read -r f; do
  rel="${f#"$gen"/}"
  if allowed "$rel"; then continue; fi
  if [ ! -f "$root/$rel" ]; then
    echo "missing: $rel"; fail=1
  elif ! cmp -s "$f" "$root/$rel"; then
    echo "differs: $rel"; diff -u "$f" "$root/$rel" | head -40 || true; fail=1
  fi
done < "$work/files"
[ "$fail" = 0 ] && echo "matches p0g_app @ ${BRICKS_REF:0:7} (allowed divergences: tool/regen.allow)"
exit "$fail"
