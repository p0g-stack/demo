// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: WorkerGenerator 9.3.2 (Squadron 7.4.4)
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'demo_service.dart';

void _start$DemoService(WorkerRequest command) {
  /// VM entry point for DemoService
  run($DemoServiceInitializer, command);
}

EntryPoint $getDemoServiceActivator(SquadronPlatformType platform) {
  if (platform.isVm) {
    return _start$DemoService;
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
