import 'dart:io';

import 'package:test/test.dart';

Future<ProcessResult> demo(List<String> args) =>
    Process.run(Platform.resolvedExecutable, ['run', 'bin/demo.dart', ...args]);

void main() {
  test(
    'partitions with root and usb switched off says why nothing ran',
    () async {
      final r = await demo([
        'partitions',
        '--off',
        'root',
        '--off',
        'usb.native',
      ]);
      expect(r.exitCode, 2, reason: '${r.stderr}');
      expect('${r.stdout}', contains('NoStrategyAvailable'));
      expect('${r.stdout}', contains('missing root'));
    },
  );

  test('serve prints a squadron_process ready line first', () async {
    final p = await Process.start(Platform.resolvedExecutable, [
      'run',
      'bin/demo.dart',
      'serve',
      '--first-link-grace-ms',
      '200',
    ]);
    final first = await p.stdout
        .transform(const SystemEncoding().decoder)
        .first;
    expect(first, contains('"squadron_process":1'));
    // Nobody connects: the host exits by itself.
    expect(await p.exitCode.timeout(const Duration(seconds: 30)), 0);
  });
}
