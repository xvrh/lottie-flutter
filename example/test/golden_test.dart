import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;
import 'utils.dart';

void main() {
  var root = 'assets';
  for (var asset in Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => const ['.json', '.zip'].contains(p.extension(f.path)))) {
    testWidgets('Goldens ${asset.path}', (tester) async {
      var size = Size(500, 400);
      tester.binding.window.physicalSizeTestValue = size;
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      var composition = await tester.runAsync(() => FileLottie(asset).load());

      await tester.pumpWidget(FilmStrip(composition, size: size));

      var folder = p.relative(asset.path, from: root);
      var fileName =
          '${p.basenameWithoutExtension(asset.path)}.png'.toLowerCase();
      await expectLater(
          find.byType(FilmStrip),
          matchesGoldenFile(
              p.join('goldens/all', p.dirname(folder), fileName)));
    });
  }
}
