# Pins

Pins: what this repo holds fixed, where, and who moves it. Values read from the repo at the commit that added this file; the bump order across repos is /mnt/project-files/proposals/flutter-bump-checklist.md (project files).

| What | Where | Current | Bumped by |
| --- | --- | --- | --- |
| flutter_p0g (the tool) | `.github/workflows/ci.yml` `env.FLUTTER_P0G_REF` | `210cc6f` | demo |
| bricks (p0g_app the app is generated from) | `tool/regen.sh` `BRICKS_REF` | `415a11a` (p0g_app 0.8.11) | demo, then `tool/regen.sh` |
| squadron_process | `core/`, `app/`, `cli/` `pubspec.yaml` `ref:` | `28c37ce` | copied from the brick by regen |
| flutter-webui | same files, `ref:` | `60c0b77` | copied from the brick by regen |
| flutter_rust_bridge Dart / Rust | `core/pubspec.yaml` `ref:` / `rust/Cargo.toml` | `848e438` / `=2.14.0-beta.2` | brick / demo |
| p0g_lints | `analysis_options.yaml` `ref:` | `8e3d47f` | copied from the brick |
| AERA runtime kit | `.github/workflows/ci.yml` `env.AERA_KIT_SHA256` (arm64 debug asset of flutter-aera release `kit-3.47.5`) | `12b9a13` (flutter-aera `d1403d6`, own engines, padding through the engine) | demo, after flutter-aera's Kit workflow republishes (the tag is clobbered, so the old hash then fails the `aera` job) |
| Flutter | `.github/workflows/ci.yml` `flutter-version` (four jobs) | 3.47.5 | demo when Flutter moves |
