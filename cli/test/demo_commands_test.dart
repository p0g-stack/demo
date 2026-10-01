import 'package:demo_cli/demo_cli.dart';
import 'package:test/test.dart';

void main() {
  test(
    'partitions with root and usb switched off finds nothing to run',
    () async {
      expect(
        await AppRunner().run([
          'partitions',
          '--off',
          'root',
          '--off',
          'usb.native',
        ]),
        2,
      );
    },
  );

  test('crunch runs the Places workload here', () async {
    expect(await AppRunner().run(['crunch', '--n', '1000']), 0);
  });
}
