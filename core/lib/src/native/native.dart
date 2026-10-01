import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import '../rust/api/demo.dart' as rust;
import '../rust/frb_generated.dart';
import 'native_stub.dart'
    if (dart.library.io) 'native_io.dart'
    if (dart.library.js_interop) 'native_web.dart'
    as impl;

/// The demo crate (`rust/`) as loaded in this isolate or Web Worker: native
/// code on the VM, single-threaded wasm on the web.
final class Native {
  const Native._(this.target, this.from, this.initMs);

  /// What the crate says it was compiled for (`x86_64-linux`,
  /// `wasm32-unknown (single-threaded)`).
  final String target;

  /// Where the library came from (a file, or the wasm prefix).
  final String from;

  /// Time to load and initialise it here.
  final int initMs;

  static Future<Native>? _loading;

  /// Loads the crate once per isolate or worker. A failure is not cached, so
  /// a later call tries again (after `tool/rust.sh`, say).
  static Future<Native> load() =>
      _loading ??= _load().catchError((Object e, StackTrace s) {
        _loading = null;
        Error.throwWithStackTrace(e, s);
      });

  static Future<Native> _load() async {
    final sw = Stopwatch()..start();
    final config = impl.loaderConfig(
      RustLib.kDefaultExternalLibraryLoaderConfig,
    );
    final lib = await loadExternalLibrary(config);
    await RustLib.init(externalLibrary: lib);
    return Native._(
      rust.buildTarget(),
      impl.describe(config),
      sw.elapsedMilliseconds,
    );
  }

  /// [rust.countPrimes] once loaded.
  int countPrimes(int n) => rust.countPrimes(n: n);
}
