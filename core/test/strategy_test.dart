import 'package:demo_core/demo_core.dart';
import 'package:test/test.dart';

Facts facts(Set<String> have) =>
    Facts({for (final f in checkedFacts) f: have.contains(f)});

String? chosen(Facts f) =>
    partitionsObjective.availableIn(Place('fake', f)).firstOrNull?.name;

void main() {
  group('partitions objective', () {
    test('prefers on device when the place has root and block devices', () {
      expect(
        chosen(
          facts({
            Fact.root,
            Fact.blockDevices,
            Fact.usbNative,
            Fact.processSpawn,
          }),
        ),
        'on_device',
      );
    });

    test('falls back to host when root is missing', () {
      final f = facts({Fact.blockDevices, Fact.usbNative, Fact.processSpawn});
      expect(chosen(f), 'from_host');
      expect(partitionStrategies.first.missing(f), {Fact.root});
    });

    test('chooses nothing in a browser place and says what is missing', () {
      final f = facts({Fact.usbWeb, Fact.net});
      expect(chosen(f), isNull);
      expect(partitionStrategies.map((s) => s.missing(f)), [
        {Fact.root, Fact.blockDevices},
        {Fact.usbNative, Fact.processSpawn},
      ]);
      expect(
        () => partitionsObjective.run(null, Place('fake', f)),
        throwsA(isA<NoStrategyAvailable>()),
      );
    });

    test('a fact switched off reads as missing', () {
      final f = withoutFacts(facts({Fact.root, Fact.blockDevices}), {
        Fact.root,
      });
      expect(f.has(Fact.root), isFalse);
      expect(chosen(f), isNull);
    });
  });

  group('parsers', () {
    test('/proc/partitions', () {
      const text =
          'major minor  #blocks  name\n\n'
          ' 259        0   65536 boot_a\n'
          '   8        0  1024 sda\n';
      final p = parseProcPartitions(text);
      expect(p.map((e) => e.name), ['boot_a', 'sda']);
      expect(p.first.bytes, 65536 * 1024);
    });

    test('fastboot getvar all', () {
      const text =
          '(bootloader) partition-size:boot_a: 0x4000000\n'
          '(bootloader) partition-type:boot_a:raw\n'
          '(bootloader) partition-size:super: 0x100000000\n';
      final p = parseFastbootGetvar(text);
      expect(p.map((e) => e.name), ['boot_a', 'super']);
      expect(p.first.bytes, 0x4000000);
    });
  });
}
