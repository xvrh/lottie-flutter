import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

/// Golden tests are rendered inside a pinned Flutter Linux container (see
/// `tool/docker_test.sh`) so the output is reproducible. This small tolerance
/// absorbs any remaining sub-pixel noise without masking real regressions.
const _goldenThreshold = 0.005; // 0.5% of pixels may differ

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (goldenFileComparator is LocalFileComparator) {
    final basedir = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = _TolerantComparator(
      Uri.parse('${basedir}flutter_test_config.dart'),
    );
  }
  await loadFonts();
  return testMain();
}

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _goldenThreshold) {
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
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
