# demo

The living reference app for p0g-stack, generated from the `p0g_app` brick
(`bricks` repo). One page per affordance, on WebUI, WebUI X, plain web and
AERA. Each page shows which facts its place reports and what the app does
without them.

## Shape

The `p0g_app` workspace: `core/` (pure Dart), `app/` (Flutter), `cli/` (Dart
CLI, also the WebUI root process), optional `rust/` via frb. Pages live under
`app/lib/pages/`; strategies (with `available(facts)`) under `core/`.

Built with `flutter_p0g build webui` / `aera` and plain `flutter build web`.

## Pages

| # | Page | Shows | State |
|---|---|---|---|
| 1 | Places | `DemoService` inline, in a Squadron worker (isolate / Web Worker) and in the root process; start and call timings, frames drawn during CPU work, and each place's own facts | inline, worker and root process run (the root process through `squadron_process`; on WebUI it waits for the brick's launcher) |
| 2 | Strategy | list partitions on the device as root, or from a host with `fastboot`, picked by `available(facts)`; facts can be switched off to see the fallback; every run is logged as a StrategyRun | runs |
| 3 | Rust | the demo crate (`rust/`) through flutter_p0g's patched frb in every place: single-threaded wasm in the page and in a Web Worker, native in an isolate and the root process; what each copy was built for, its load time, Rust against Dart; the Dart version where the crate can't load | runs on plain web (Web Workers need the frb worker patch, sent to flutter_p0g as its 0003) |
| 4 | Lifecycle | a five-minute task: hidden keeps going (ticks stamped by the place's clock), closed stops (the next start reports where it ended) | runs |
| 5 | Shell basics | insets, keyboard, back and exit, light and dark through Flutter's own APIs; what this host gives for each and what every known manager gives (flutter_webui_client's fake hosts), with the fallback | runs |
| 6 | Plugins | pick, save, share, URL, clipboard through `webui-packages` | stub: each plugin says "unavailable here" until webui-packages ships it |

The workspace is exactly what the `p0g_app` brick (bricks @ 204bbf0, 0.7.3,
with `rust`) generates, plus the pages (`app/lib/pages/`, opened from a panel on the
brick's home), the demo's core (`DemoService`, the `partitions` objective,
the page places, the Rust loader), the crate's `demo` module and two CLI
commands. Edits to generated files are insertions at the brick's `// p0g:`
markers plus the few listed with a reason in `tool/regen.allow`;
`tool/regen.sh` regenerates the workspace in CI and fails on anything else.

The root process comes from the brick's `Places`: `P0G_CLI` on a desktop,
flutter-webui's root channel on WebUI. For development on plain web, point a
page at a running `demo serve`: `?place=<port>&token=<token>`.

## Run

Pinned Flutter 3.47.5.

```sh
flutter_p0g precache --frb                # before bootstrap, for page 3's wasm (else native only)
PLATFORMS=web bash tool/bootstrap.sh      # patched Squadron, Rust (tool/rust.sh), codegen, web/, web workers, format
(cd app && flutter run -d chrome)         # plain web
(cd app && flutter build web --release --no-web-resources-cdn)
dart run cli/bin/demo.dart facts          # what the CLI's own process can do
dart run cli/bin/demo.dart partitions     # the Strategy page's objective, from the CLI
dart run cli/bin/demo.dart serve          # root process; first line {"squadron_process":1,"port":..,"token":..}
tool/regen.sh                             # still what p0g_app generates? (needs mason)
```

The WebUI module (`app/webui/` and `app/aera/` are what `flutter_p0g create`
added). The Android crate comes from CI's `native-android` branch or
`cargo ndk -t arm64-v8a -t x86_64 -o ../build/native-android build --release`
in `rust/`:

```sh
flutter_p0g precache --frb --webui --dart-android --dart-android-abi=arm64-v8a,x86_64
(cd app && flutter_p0g build webui --device-rust-libs="$PWD/../build/native-android")
```

CI packs the same zip on every push to main and publishes it on the `module`
branch with its SHA256SUMS, `update.json` and `changelog.md`. `updateJson` in
`app/webui/module.prop` points managers' update button at the latest GitHub
release, so a release carries those three files: CI publishes one on every
push to main, `v0.<minor>.<run number>` (the run number is also the
versionCode), so the zip is `demo-v0.<minor>.<run>.zip`.

Tests are unit and widget tests against fake places (`dart test` in `core/`
and `cli/`, `flutter test` in `app/`); no e2e.

## License

LGPL-3.0-or-later with the LGPL-3.0 linking exception
(`LICENSE`, `LICENSE.exception`; SPDX `LGPL-3.0-or-later WITH LGPL-3.0-linking-exception`).
