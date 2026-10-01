import 'dart:io';

import 'package:test/test.dart';

Future<ProcessResult> demo(List<String> args) =>
    Process.run(Platform.resolvedExecutable, ['run', 'bin/demo.dart', ...args]);

void main() {
  test('facts lists every fact', () async {
    final r = await demo(['facts']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect('${r.stdout}', contains('process.spawn'));
  });

  test('partitions with every fact masked says why nothing ran', () async {
    final r = await demo([
      'partitions',
      '--mask',
      'root',
      '--mask',
      'usb.native',
    ]);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('no strategy fits'));
  });
}
