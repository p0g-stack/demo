import 'package:demo_core/demo_core.dart';
import 'package:test/test.dart';

/// The demo crate either loads and agrees with Dart, or says how to build
/// it. Which one depends on whether tool/rust.sh has run.
void expectRust(Map<String, dynamic> r) {
  if (r.containsKey('error')) {
    expect(r['error'], contains('tool/rust.sh'));
  } else {
    expect(r['count'], 25);
    expect(r['target'], isNotEmpty);
  }
}

void main() {
  test('inline: the crate counts like crunch', () async {
    final r = await DemoService().rustCrunch(100);
    expectRust(r);
    expect((await DemoService().crunch(100))['count'], 25);
  });

  test('in a Squadron isolate the crate loads again', () async {
    final w = DemoServiceWorker();
    addTearDown(w.stop);
    expectRust(await w.rustCrunch(100));
  });
}
