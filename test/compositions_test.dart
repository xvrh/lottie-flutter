import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/composition.dart';
import 'package:lottie/src/lottie_drawable.dart';
import 'package:path/path.dart' as p;

void main() {
  var assetsPath = 'example/assets';
  for (var file
      in Directory(assetsPath)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))) {
    test('Parse and draw ${p.relative(file.path, from: assetsPath)}', () async {
      var composition = await LottieComposition.fromBytes(
        file.readAsBytesSync(),
      );
      expect(composition, isNotNull);

      var drawable = LottieDrawable(composition);

      var recorder = PictureRecorder();
      var canvas = Canvas(recorder);
      for (var progress = 0; progress <= 100; progress += 20) {
        drawable
          ..setProgress(progress / 100)
          ..draw(canvas, const Rect.fromLTWH(0, 0, 200, 200));
      }
    });
  }
}
