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
| 3 | Rust | a crate through patched frb, native and wasm in a worker | next |
| 4 | Lifecycle | a five-minute task: hidden keeps going (ticks stamped by the place's clock), closed stops (the next start reports where it ended) | runs |
| 5 | Shell basics | insets, keyboard, back and exit at root, light and dark | next |
| 6 | Plugins | pick, save, share, URL, clipboard through `webui-packages` | next |

The workspace is what the `p0g_app` brick (bricks @ 6bab8b4) generates, plus
the pages, the demo's core and CLI commands. `tool/regen.sh` regenerates it in
CI and fails on any difference not listed in `tool/regen.allow`. Strategies use
the brick's `Objective` and logging; places come from `squadron_process`, with
the facts checked by `core/lib/src/facts_check/`.

The root process still has no launcher on WebUI (the brick wires one over
flutter-webui's root channel once its `process_place` variant matches
squadron_process). For development, point a page at a running `demo serve`:
`?place=<port>&token=<token>`.

## Run

Pinned Flutter 3.47.5.

```sh
tool/deps.sh                              # squadron_process + patched Squadron (pubspec_overrides.yaml)
PLATFORMS=web bash tool/bootstrap.sh      # codegen, web/, web workers, format
(cd app && flutter run -d chrome)         # plain web
(cd app && flutter build web --release --no-web-resources-cdn)
dart run cli/bin/demo.dart facts          # what the CLI's own process can do
dart run cli/bin/demo.dart partitions     # the Strategy page's objective, from the CLI
dart run cli/bin/demo.dart serve          # root process; first line {"squadron_process":1,"port":..,"token":..}
tool/regen.sh                             # still what p0g_app generates? (needs mason)
```

Tests are unit and widget tests against fake places (`dart test` in `core/`
and `cli/`, `flutter test` in `app/`); no e2e.

## License

LGPL-3.0-or-later with the LGPL-3.0 linking exception
(`LICENSE`, `LICENSE.exception`; SPDX `LGPL-3.0-or-later WITH LGPL-3.0-linking-exception`).
