#!/usr/bin/env bash
# Builds page 3's Rust: points the crate and core at flutter_p0g's patched
# frb, regenerates the bindings, builds the native library (for the CLI, the
# Dart VM and tests) and the single-threaded wasm (for the page and its Web
# Workers). Run after tool/bootstrap.sh. Needs `flutter_p0g precache --frb`.
#
# The links to the patched frb are local paths, so they go in gitignored
# files, as squadron_patch does for Squadron: rust/.cargo/config.toml
# ([patch.crates-io]) and a flutter_rust_bridge entry in
# pubspec_overrides.yaml.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter_root="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")"
frb="$flutter_root/bin/cache/flutter_p0g/frb"
codegen="$frb/bin/flutter_rust_bridge_codegen"
if [ ! -x "$codegen" ]; then
  echo "The patched frb is not built: run \`flutter_p0g precache --frb\`." >&2
  exit 1
fi

mkdir -p rust/.cargo
echo '*' > rust/.cargo/.gitignore
cat > rust/.cargo/config.toml <<TOML
# Written by tool/rust.sh: flutter_p0g's patched frb.
[patch.crates-io]
flutter_rust_bridge = { path = "$frb/src/frb_rust" }
TOML

if ! grep -q '^  flutter_rust_bridge:' pubspec_overrides.yaml 2>/dev/null; then
  [ -f pubspec_overrides.yaml ] || echo 'dependency_overrides:' > pubspec_overrides.yaml
  cat >> pubspec_overrides.yaml <<YAML
  # flutter_p0g's patched frb (tool/rust.sh).
  flutter_rust_bridge:
    path: $frb/src/frb_dart
YAML
fi
flutter pub get >/dev/null

"$codegen" generate
(cd rust && cargo build --release)
# wasm-pack runs wasm-opt from binaryen 117, downloading it if needed. An
# older system wasm-opt (binaryen 108) produced a module whose externref
# table failed to grow at init.
"$codegen" build-web --no-threads --release --dart-root core -o "$PWD/app/web"
dart format core/lib/src/rust >/dev/null
