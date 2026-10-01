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
| 1 | Places | `DemoService` inline, in a Squadron worker (isolate / Web Worker) and in the root process; start and call timings, frames drawn during CPU work, and each place's own facts | inline + worker run; root process shown as missing until `squadron_process` lands |
| 2 | Strategy | list partitions on the device as root, or from a host with `fastboot`, picked by `available(facts)`; facts can be switched off to see the fallback; every run goes to the ledger | runs |
| 3 | Rust | a crate through patched frb, native and wasm in a worker | next |
| 4 | Lifecycle | a five-minute task: hidden keeps going (ticks stamped by the place's clock), closed stops (the next start reports where it ended) | runs |
| 5 | Shell basics | insets, keyboard, back and exit at root, light and dark | next |
| 6 | Plugins | pick, save, share, URL, clipboard through `webui-packages` | next |

Interim, until the shared pieces exist: `core/lib/src/places/place.dart` is a
stand-in for `squadron_process` places, and the workspace is hand-written in
the `p0g_app` shape until the brick can regenerate it.

## Run

Pinned Flutter 3.47.5.

```sh
flutter pub get
(cd core && dart run build_runner build)   # only after changing DemoService
tool/build_workers.sh                      # compiles the Web Worker into app/web/workers/
(cd app && flutter run -d chrome)          # plain web
(cd app && flutter build web --release --no-web-resources-cdn)
dart run cli/bin/demo.dart facts           # what the CLI's own process can do
dart run cli/bin/demo.dart partitions      # Strategy page task, from the CLI
```

Tests are unit and widget tests against fake places (`dart test` in `core/`
and `cli/`, `flutter test` in `app/`); no e2e.

## License

LGPL-3.0-or-later with the LGPL-3.0 linking exception
(`LICENSE`, `LICENSE.exception`; SPDX `LGPL-3.0-or-later WITH LGPL-3.0-linking-exception`).
