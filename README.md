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

## License

LGPL-3.0-or-later with the LGPL-3.0 linking exception
(`LICENSE`, `LICENSE.exception`; SPDX `LGPL-3.0-or-later WITH LGPL-3.0-linking-exception`).
