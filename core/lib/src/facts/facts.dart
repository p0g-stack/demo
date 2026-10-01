/// Names of the facts a place reports about itself.
///
/// Facts come from the place a service runs in, never from the platform the
/// app was built for: the page and the root process on the same phone report
/// different facts, and that difference is the point.
abstract final class Fact {
  /// The place runs as uid 0.
  static const root = 'root';

  /// The place can open a block device for reading.
  static const blockDevices = 'block_devices';

  /// USB device nodes are present (native USB, e.g. `fastboot`).
  static const usbNative = 'usb.native';

  /// WebUSB (`navigator.usb`) is present.
  static const usbWeb = 'usb.web';

  /// The place can start child processes.
  static const processSpawn = 'process.spawn';

  /// Files written now are there on the next start.
  static const fsPersistent = 'fs.persistent';

  /// The place reports a network.
  static const net = 'net';

  static const all = [
    root,
    blockDevices,
    usbNative,
    usbWeb,
    processSpawn,
    fsPersistent,
    net,
  ];
}

/// What one place reported about itself.
final class Facts {
  const Facts({
    required this.runtime,
    required this.values,
    this.notes = const {},
    this.masked = const {},
  });

  /// An empty report, for a place that never answered.
  const Facts.none(this.runtime)
    : values = const {},
      notes = const {},
      masked = const {};

  /// What the place is, as it describes itself (e.g. `dart vm (isolate)`).
  final String runtime;

  /// Fact name to whether the place has it. A fact absent from the map was
  /// not reported, which reads the same as `false`.
  final Map<String, bool> values;

  /// How each fact was decided, for display.
  final Map<String, String> notes;

  /// Facts the user switched off to see the fallback; they read as missing.
  final Set<String> masked;

  bool has(String fact) => !masked.contains(fact) && (values[fact] ?? false);

  /// The facts from [needed] this place does not have.
  Set<String> missing(Iterable<String> needed) => {
    for (final f in needed)
      if (!has(f)) f,
  };

  /// The same report with [facts] read as missing.
  Facts mask(Set<String> facts) =>
      Facts(runtime: runtime, values: values, notes: notes, masked: facts);

  Map<String, dynamic> toJson() => {
    'runtime': runtime,
    'values': values,
    'notes': notes,
  };

  factory Facts.fromJson(Map json) => Facts(
    runtime: json['runtime'] as String,
    values: {
      for (final e in (json['values'] as Map).entries)
        e.key as String: e.value == true,
    },
    notes: {
      for (final e in ((json['notes'] as Map?) ?? const {}).entries)
        e.key as String: '${e.value}',
    },
  );

  @override
  String toString() =>
      '$runtime {${[for (final f in Fact.all)
        if (has(f)) f].join(', ')}}';
}
