# demo

The living reference app for p0g-stack, generated from the `p0g_app` brick
(`bricks` repo). One page per affordance, on WebUI, WebUI X, plain web and
AERA. Each page shows which facts its place reports and what the app does
without them.

## Shape

The `p0g_app` workspace: `core/` (pure Dart), `app/` (Flutter), `cli/` (Dart
CLI, also the WebUI root process), optional `rust/` via frb. Pages live under
`app/lib/pages/`; strategies (with `available(facts)`) under `core/`.

Built with `flutter_p0g build webui` / `aera` / `web`. The plain web build
runs at https://p0g-stack.github.io/demo/.

## Pages

| # | Page | Shows | State |
|---|---|---|---|
| 1 | Places | `DemoService` inline, in a Squadron worker (isolate / Web Worker) and in the root process; start and call timings, frames drawn during CPU work, and each place's own facts | inline, worker and root process run (the root process through `squadron_process`; on WebUI it waits for the brick's launcher) |
| 2 | Strategy | list partitions on the device as root, or from a host with `fastboot`, picked by `available(facts)`; facts can be switched off to see the fallback; every run is logged as a StrategyRun | runs |
| 3 | Rust | the demo crate (`rust/`) through flutter_p0g's patched frb in every place: single-threaded wasm in the page and in a Web Worker, native in an isolate and the root process; what each copy was built for, its load time, Rust against Dart; the Dart version where the crate can't load | runs on plain web (Web Workers need the frb worker patch, sent to flutter_p0g as its 0003) |
| 4 | Lifecycle | a five-minute task: hidden keeps going (ticks stamped by the place's clock), closed stops (the next start reports where it ended) | runs |
| 5 | Shell basics | insets, keyboard, back and exit, light and dark through Flutter's own APIs; what this host gives for each and what every known manager gives (flutter_webui_client's fake hosts), with the fallback | runs |
| 6 | Plugins | share, the camera permission, copy and paste, pick a file, and a notification through the stock plugins, with the route `webui-packages` gives each on WebUI | runs |

The workspace is exactly what the `p0g_app` brick (0.9.1, pinned by
`BRICKS_REF` in `.github/workflows/ci.yml`, with `rust` and `sample`) generates,
plus the pages (`app/lib/pages/`, opened from a panel on the
brick's home), the demo's core (`DemoService`, the `partitions` objective,
the page places, the Rust loader), the crate's `demo` module and two CLI
commands. Edits to generated files are insertions at the brick's `// p0g:`
markers plus the few listed with a reason in `tool/regen.allow`, and lines
added (never changed) in the files listed in `tool/regen.add`;
`tool/regen.sh` regenerates the workspace in CI and fails on anything else.

The root process comes from the brick's `Places`: `P0G_CLI` on a desktop,
flutter-webui's root channel on WebUI. For development on plain web, point a
page at a running `demo serve`: `?place=<port>&token=<token>`.

## Run

Pinned Flutter 3.47.9 (Dart 3.13.7).

```sh
flutter_p0g precache --frb --no-webui      # required verified FRB cache before bootstrap
PLATFORMS=web bash tool/bootstrap.sh      # patched Squadron, Rust (tool/rust.sh), codegen, web/, web workers, format
(cd app && flutter run -d chrome)         # plain web
(cd app && flutter_p0g build web --release)  # plain web, Rust wasm and Web Workers in build/web
dart run cli/bin/demo.dart facts          # what the CLI's own process can do
dart run cli/bin/demo.dart partitions     # the Strategy page's objective, from the CLI
dart run cli/bin/demo.dart serve          # root process; first line {"squadron_process":1,"port":..,"token":..}
BRICKS_REF=<full-sha-from-ci.yml> bash tool/regen.sh  # needs mason; never overwrites the app
```

The WebUI module (`app/webui/` and `app/aera/` are what `flutter_p0g create`
added). The Android crate comes from CI's `native-android` branch or
`cargo ndk -t arm64-v8a -t x86_64 -o ../build/native-android build --release`
in `rust/`:

```sh
flutter_p0g precache --frb --webui --dart-android --dart-android-abi=arm64-v8a,x86_64
(cd app && flutter_p0g build webui --device-rust-libs="$PWD/../build/native-android")
```

CI validates every push to main and uploads candidate artifacts; it does not
publish a release or update artifact branches. The separate manual
`promote.yml` requires the successful source validation run, manager lab
qualification and the exact successful AERA Kit attempt. It promotes those
same bytes without rebuilding. `updateJson` in `app/webui/module.prop` points
at the latest promoted release. Versions remain `v0.<minor>.<source run number>`
(the source run number is also the versionCode).

CI builds plain web under `/demo/`. Local qualification runs both JavaScript
and dart2wasm builds through the unchanged `tool/web_smoke.mjs`: Rust must run
inline and in a Web Worker, and the worker digest must select `rust_sha2`,
without COOP/COEP. Only the qualified candidate's site is eligible for the
`web` branch served by GitHub Pages.

The AERA plugin comes from `flutter_p0g build aera --debug` against
flutter-aera's source-tagged 3.47.9 kit (debug only), verified against the
committed SHA256 in CI. The candidate contains `Flutter-Demo-<version>.aerap`;
only promotion publishes it to a release and the `aera` branch.
The demo crate goes in it too, cross-built for aarch64 Linux
(`gcc-aarch64-linux-gnu` as the linker).

Tests are unit and widget tests against fake places (`dart test` in `core/`
and `cli/`, `flutter test` in `app/`); the one end-to-end check is that web
smoke check.

## License

LGPL-3.0-or-later with the LGPL-3.0 linking exception
(`LICENSE`, `LICENSE.exception`; SPDX `LGPL-3.0-or-later WITH LGPL-3.0-linking-exception`).
