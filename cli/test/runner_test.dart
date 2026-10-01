import 'package:test/test.dart';
import 'package:demo_cli/demo_cli.dart';
import 'package:demo_core/demo_core.dart';

void main() {
  test('hello runs', () async {
    expect(await AppRunner().run(['hello', 'cli']), 0);
  });

  test('an unknown command is a usage error', () async {
    expect(await AppRunner().run(['nope']), 64);
  });

  test('serve rejects an unknown option', () async {
    expect(await AppRunner().run(['serve', '--nope']), 64);
  });

  test('the CLI checks its own facts', () async {
    final place = await cliPlace();
    expect(place.kind, 'cli');
    expect(place.facts[Fact.processSpawn], isA<bool>());
  });
}
