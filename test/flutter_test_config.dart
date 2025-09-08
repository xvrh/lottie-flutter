import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadFonts();
  return testMain();
}

Future<void> loadFonts() async {
  for (var file in Directory(
    'example/assets/fonts',
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.ttf'))) {
    var fontLoader = FontLoader(
      path.basenameWithoutExtension(file.path).replaceAll('-', ' '),
    );
    var future = file.readAsBytes().then((value) => value.buffer.asByteData());
    fontLoader.addFont(future);
    await fontLoader.load();
  }
}
