import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

/// The wasm is built into the app's `web/pkg/` (tool/rust.sh). A page
/// resolves `pkg/` against its base href; a Squadron Web Worker lives in
/// `workers/` beside it and resolves against its own script URL. Loading in
/// a worker needs flutter_p0g's frb patch for workers.
ExternalLibraryLoaderConfig loaderConfig(ExternalLibraryLoaderConfig base) =>
    ExternalLibraryLoaderConfig(
      stem: base.stem,
      ioDirectory: base.ioDirectory,
      webPrefix: globalContext.has('document') ? 'pkg/' : '../pkg/',
    );

String describe(ExternalLibraryLoaderConfig config) =>
    '${config.webPrefix}${config.stem}_bg.wasm';
