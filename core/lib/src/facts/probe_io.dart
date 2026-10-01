import 'dart:io';
import 'dart:isolate';

import 'facts.dart';

Future<Facts> probe(String? as) async {
  final values = <String, bool>{};
  final notes = <String, String>{};
  void put(String fact, bool value, String note) {
    values[fact] = value;
    notes[fact] = note;
  }

  final uid = _uid();
  put(Fact.root, uid == 0, uid == null ? 'uid unknown' : 'uid $uid');

  final block = _readableBlockDevice();
  put(
    Fact.blockDevices,
    block != null,
    block == null ? 'no block device opened' : 'opened $block',
  );

  final usb = Directory('/dev/bus/usb').existsSync();
  put(Fact.usbNative, usb, usb ? '/dev/bus/usb present' : 'no /dev/bus/usb');
  put(Fact.usbWeb, false, 'not a browser');

  var spawn = false;
  try {
    spawn = (await Process.run('true', const [])).exitCode == 0;
  } on Object {
    spawn = false;
  }
  put(Fact.processSpawn, spawn, spawn ? 'ran `true`' : 'cannot start `true`');

  put(Fact.fsPersistent, true, 'dart:io filesystem');

  var net = false;
  try {
    net = (await NetworkInterface.list()).isNotEmpty;
  } on Object {
    net = false;
  }
  put(Fact.net, net, net ? 'non-loopback interface' : 'no interface');

  final where = Isolate.current.debugName ?? 'main';
  return Facts(
    runtime: as ?? 'dart vm, ${Platform.operatingSystem}, isolate "$where"',
    values: values,
    notes: notes,
  );
}

int? _uid() {
  try {
    final status = File('/proc/self/status').readAsLinesSync();
    final line = status.firstWhere((l) => l.startsWith('Uid:'));
    return int.parse(line.split(RegExp(r'\s+'))[1]);
  } on Object {
    return null;
  }
}

/// The first block device this process can actually read, or null.
String? _readableBlockDevice() {
  final Directory sys = Directory('/sys/class/block');
  if (!sys.existsSync()) return null;
  for (final entry in sys.listSync()) {
    final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
    for (final dev in ['/dev/block/$name', '/dev/$name']) {
      try {
        final f = File(dev).openSync();
        f.readSync(1);
        f.closeSync();
        return dev;
      } on Object {
        continue;
      }
    }
  }
  return null;
}
