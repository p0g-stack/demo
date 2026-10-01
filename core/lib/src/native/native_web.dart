import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

/// Web: frb's own loader fetches `pkg/<stem>.js` and its wasm, which
/// `flutter_p0g build webui` builds single-threaded (no COOP/COEP needed).
/// A page resolves `pkg/` against its base href; a Squadron Web Worker
/// resolves against its own script, which lives in `workers/` beside it.
Future<ExternalLibrary?> openNativeLibrary(String stem) async =>
    loadExternalLibrary(
      ExternalLibraryLoaderConfig(
        stem: stem,
        ioDirectory: null,
        webPrefix: globalContext.has('document') ? 'pkg/' : '../pkg/',
      ),
    );
