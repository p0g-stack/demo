import 'dart:io';

File get _file => File('${Directory.systemTemp.path}/p0g_demo_lifecycle.json');

String? read() {
  try {
    return _file.readAsStringSync();
  } on Object {
    return null;
  }
}

void write(String s) {
  try {
    _file.writeAsStringSync(s);
  } on Object {
    // Best effort: the page still works, it just cannot report the last run.
  }
}
