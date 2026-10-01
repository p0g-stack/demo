import 'dart:io';

import '../facts.dart';

Future<Map<String, Object?>> checkFacts() async => {
  Fact.root: _uid() == 0,
  Fact.blockDevices: _readableBlockDevice(),
  Fact.usbNative: _lists('/dev/bus/usb'),
  Fact.usbWeb: false,
  Fact.processSpawn: await _spawns(),
  Fact.fsPersistent: _writableTemp(),
  Fact.net: await _network(),
};

/// Effective uid, from the second field of `Uid:` (Linux and Android).
int? _uid() {
  try {
    final line = File(
      '/proc/self/status',
    ).readAsLinesSync().firstWhere((l) => l.startsWith('Uid:'));
    return int.parse(line.split(RegExp(r'\s+'))[2]);
  } on Object {
    return null;
  }
}

/// A block device the kernel lists that this process can open for reading.
bool _readableBlockDevice() {
  try {
    for (final e in Directory('/sys/class/block').listSync()) {
      final name = e.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      for (final node in ['/dev/block/$name', '/dev/$name']) {
        try {
          File(node).openSync().closeSync();
          return true;
        } on Object {
          continue;
        }
      }
    }
  } on Object {
    // no sysfs
  }
  return false;
}

bool _lists(String dir) {
  try {
    return Directory(dir).listSync().isNotEmpty;
  } on Object {
    return false;
  }
}

Future<bool> _spawns() async {
  try {
    final sh = File('/system/bin/sh').existsSync() ? '/system/bin/sh' : 'sh';
    return (await Process.run(sh, const ['-c', 'exit 0'])).exitCode == 0;
  } on Object {
    return false;
  }
}

bool _writableTemp() {
  try {
    Directory.systemTemp.createTempSync('p0g').deleteSync();
    return true;
  } on Object {
    return false;
  }
}

Future<bool> _network() async {
  try {
    return (await NetworkInterface.list()).isNotEmpty;
  } on Object {
    return false;
  }
}
