/// Whether the code is running inside `flutter test` (web variant, best
/// effort: the VM test runner exposes FLUTTER_TEST as a process environment
/// variable instead, handled in the io variant).
const bool isRunningInFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
