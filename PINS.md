# Pins

Pins: what this repo holds fixed, where, and who moves it. Values read from the repo at the commit that added this file; the bump order across repos is https://github.com/p0g-stack/.github/blob/main/docs/flutter-bump.md.

| What | Where | Current | Bumped by |
| --- | --- | --- | --- |
| flutter_p0g (the tool) | `.github/workflows/ci.yml` `env.FLUTTER_P0G_REF` | `2612b4d73a4f643d49f30d0940917b15f4ae09a3` | demo |
| bricks (p0g_app the app is generated from) | `.github/workflows/ci.yml` `env.BRICKS_REF` | `4db4a419a44da5ae5f49c97bb21e2a5633b029b1` (p0g_app 0.9.2) | demo, then `BRICKS_REF=<full-sha> bash tool/regen.sh` |
| squadron_process | `core/`, `app/`, `cli/` `pubspec.yaml` `ref:` | `8f639eb8d2e200866ace17cca03c9d7c4705f5f9` | copied from the brick by regen |
| flutter-webui | same files, `ref:` | `72df180304562037fbc720153967fbb70a362eb1` (WebUI X v660/root WifiEnable, compatible 3.47.9 branch) | copied from the brick by regen |
| flutter_rust_bridge Dart / Rust | `core/pubspec.yaml` `ref:` / `rust/Cargo.toml` | `1e4df906b6d0e96aefbfa40dde5fa2833d417c1a` / `=2.14.0-beta.2` | brick / demo |
| p0g_lints | `analysis_options.yaml` `ref:` | `8e3d47f` | copied from the brick |
| AERA runtime kit | `.github/workflows/ci.yml` `env.AERA_KIT_URL`, `env.AERA_KIT_SHA256` | `kit-3.47.9-0c28b4e291849f008d7ee3fd063e2670d0f9116b`, arm64 debug SHA256 `31c2131acd5966a50e96b9438c6e48d63126be806fcbe4da747479ae6a56caed`; Kit run `44043686997`, successful attempt 1 | demo, from flutter_p0g's committed artifact table; immutable source-tagged bytes |
| Flutter | `.github/workflows/ci.yml` `flutter-version` (four jobs) | 3.47.9 / Dart 3.13.7 | demo when Flutter moves |
| patched_source | root `pubspec.yaml` dev dependency | `d3b6de00bd5e88910b9b42036a819b06159085f5` | frozen helper-package identity shared with the brick |
