import 'package:demo_core/demo_core.dart';
import 'package:test/test.dart';

Facts facts(Set<String> have) => Facts(
  runtime: 'fake',
  values: {for (final f in Fact.all) f: have.contains(f)},
);

void main() {
  group('pick', () {
    test('prefers on device when the place has root and block devices', () {
      final s = pick(
        partitionStrategies,
        facts({
          Fact.root,
          Fact.blockDevices,
          Fact.usbNative,
          Fact.processSpawn,
        }),
      );
      expect(s.chosen, isA<OnDevicePartitions>());
      expect(s.why, contains('on device'));
    });

    test('falls back to host when root is missing', () {
      final s = pick(
        partitionStrategies,
        facts({Fact.blockDevices, Fact.usbNative, Fact.processSpawn}),
      );
      expect(s.chosen, isA<FromHostPartitions>());
      expect(s.why, contains('skipped (missing root)'));
    });

    test('chooses nothing in a browser place and says why', () {
      final s = pick(partitionStrategies, facts({Fact.usbWeb, Fact.net}));
      expect(s.chosen, isNull);
      expect(s.considered.map((a) => a.missing), [
        {Fact.root, Fact.blockDevices},
        {Fact.usbNative, Fact.processSpawn},
      ]);
      expect(s.why, startsWith('no strategy fits'));
    });

    test('a masked fact reads as missing', () {
      final f = facts({Fact.root, Fact.blockDevices}).mask({Fact.root});
      expect(f.has(Fact.root), isFalse);
      expect(pick(partitionStrategies, f).chosen, isNull);
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

  test('facts round-trip through json', () {
    final f = Facts(
      runtime: 'r',
      values: {Fact.root: true},
      notes: {Fact.root: 'uid 0'},
    );
    final back = Facts.fromJson(f.toJson());
    expect(back.has(Fact.root), isTrue);
    expect(back.notes[Fact.root], 'uid 0');
  });
}
