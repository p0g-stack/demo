import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

/// Where the native library can be: `DEMO_NATIVE_DIR`, beside the running
/// executable (a module's `bin/`, where flutter_p0g puts it), or the crate's
/// release build from the workspace root or one of its packages.
List<String> nativeDirs() => [
  ?Platform.environment['DEMO_NATIVE_DIR'],
  File(Platform.resolvedExecutable).parent.path,
  'rust/target/release',
  '../rust/target/release',
];

String _file(String stem) => Platform.isMacOS
    ? 'lib$stem.dylib'
    : Platform.isWindows
    ? '$stem.dll'
    : 'lib$stem.so';

ExternalLibraryLoaderConfig loaderConfig(ExternalLibraryLoaderConfig base) {
  final name = _file(base.stem);
  for (final dir in nativeDirs()) {
    final file = File('$dir/$name');
    if (file.existsSync()) {
      return ExternalLibraryLoaderConfig(
        stem: base.stem,
        ioDirectory: '${file.parent.absolute.path}/',
        webPrefix: base.webPrefix,
      );
    }
  }
  throw StateError(
    '$name not found in ${nativeDirs().join(', ')} (build it with tool/rust.sh)',
  );
}

String describe(ExternalLibraryLoaderConfig config) =>
    '${config.ioDirectory}${_file(config.stem)}';
