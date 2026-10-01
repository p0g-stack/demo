// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'demo_service.dart';

// **************************************************************************
// Generator: WorkerGenerator 9.3.2 (Squadron 7.4.4)
// **************************************************************************

// dart format width=80
/// Command ids used in operations map
const int _$crunchId = 1;
const int _$partitionsId = 2;
const int _$ticksId = 3;

/// WorkerService operations for DemoService
extension on DemoService {
  OperationsMap _$getOperations() => OperationsMap({
    _$crunchId: ($req) async {
      final Map<String, dynamic> $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await crunch($dsr.$0($req.args[0]));
      } finally {}
      return $res;
    },
    _$partitionsId: ($req) async {
      final List<Map<String, dynamic>> $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await partitions($dsr.$1($req.args[0]));
      } finally {}
      return $res;
    },
    _$ticksId: ($req) {
      final Stream<Map<String, dynamic>> $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = ticks($dsr.$0($req.args[0]), $dsr.$0($req.args[1]));
      } finally {}
      return $res;
    },
  });
}

/// Invoker for DemoService, implements the public interface to invoke the
/// remote service.
base mixin _$DemoService$Invoker on Invoker implements DemoService {
  @override
  Future<Map<String, dynamic>> crunch(int n) async {
    final dynamic $res = await send(_$crunchId, args: [n]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$3($res);
    } finally {}
  }

  @override
  Future<List<Map<String, dynamic>>> partitions(String id) async {
    final dynamic $res = await send(_$partitionsId, args: [id]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$4($res);
    } finally {}
  }

  @override
  Stream<Map<String, dynamic>> ticks(int count, int intervalMs) {
    final Stream $res = stream(_$ticksId, args: [count, intervalMs]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $res.map($dsr.$3);
    } finally {}
  }
}

/// Facade for DemoService, implements other details of the service unrelated to
/// invoking the remote service.
base mixin _$DemoService$Facade implements DemoService {}

/// WorkerClient for DemoService
final class $DemoService$Client extends WorkerClient
    with _$DemoService$Invoker, _$DemoService$Facade
    implements DemoService {
  $DemoService$Client(PlatformChannel channelInfo)
    : super(Channel.deserialize(channelInfo)!);
}

/// Local worker extension for DemoService
extension $DemoServiceLocalWorkerExt on DemoService {
  // Get a fresh local worker instance.
  LocalWorker<DemoService> getLocalWorker([
    ExceptionManager? exceptionManager,
  ]) => LocalWorker.create(this, _$getOperations(), exceptionManager);
}

/// WorkerService class for DemoService
base class _$DemoService$WorkerService extends DemoService
    implements WorkerService {
  _$DemoService$WorkerService() : super();

  @override
  OperationsMap get operations => _$getOperations();
}

/// Service initializer for DemoService
WorkerService $DemoServiceInitializer(WorkerRequest $req) =>
    _$DemoService$WorkerService();

/// Worker for DemoService
base class DemoServiceWorker extends Worker
    with _$DemoService$Invoker, _$DemoService$Facade
    implements DemoService {
  // ignore: use_super_parameters
  DemoServiceWorker({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $DemoServiceActivator(Squadron.platformType),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  DemoServiceWorker.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $DemoServiceActivator(SquadronPlatformType.vm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  DemoServiceWorker.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $DemoServiceActivator(SquadronPlatformType.js),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  DemoServiceWorker.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $DemoServiceActivator(SquadronPlatformType.wasm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  @override
  List? getStartArgs() => null;
}

/// Worker pool for DemoService
base class DemoServiceWorkerPool extends WorkerPool<DemoServiceWorker>
    with _$DemoService$Facade
    implements DemoService {
  // ignore: use_super_parameters
  DemoServiceWorkerPool({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => DemoServiceWorker(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  DemoServiceWorkerPool.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => DemoServiceWorker.vm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  DemoServiceWorkerPool.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => DemoServiceWorker.js(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  DemoServiceWorkerPool.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => DemoServiceWorker.wasm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  @override
  Future<Map<String, dynamic>> crunch(int n) => execute((w) => w.crunch(n));

  @override
  Future<List<Map<String, dynamic>>> partitions(String id) =>
      execute((w) => w.partitions(id));

  @override
  Stream<Map<String, dynamic>> ticks(int count, int intervalMs) =>
      stream((w) => w.ticks(count, intervalMs));
}

final class _$Deser extends MarshalingContext {
  _$Deser({super.contextAware});
  late final $0 = value<int>();
  late final $1 = value<String>();
  late final $2 = value<Object>();
  late final $3 = nmap<String, Object>(kcast: $1, vcast: $2);
  late final $4 = list<Map<String, dynamic>>($3);
}
