import 'dart:io';

/// Whether the code is running inside `flutter test`, detected the same way
/// as `foundation.defaultTargetPlatform` does.
final bool isRunningInFlutterTest = Platform.environment.containsKey(
  'FLUTTER_TEST',
);
