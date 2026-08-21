import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/composition.dart';
import 'package:lottie/src/lottie_drawable.dart';
import 'package:lottie/src/utils/utils.dart';

void main() {
  test(
    'applyTrimPathIfNeeded does not assign extractPath back onto the source',
    () {
      var path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      var originalLength = path.computeMetrics().first.length;

      var trimmed = Utils.applyTrimPathIfNeeded(path, 0.25, 0.75, 0);

      expect(
        path.computeMetrics().first.length,
        closeTo(originalLength, 0.01),
        reason:
            'the source path must stay intact, otherwise the extracted path '
            'references itself and CanvasKit overflows the stack (#411)',
      );
      expect(
        trimmed.computeMetrics().first.length,
        closeTo(originalLength * 0.5, 0.5),
      );
      expect(identical(trimmed, path), isFalse);
    },
  );

  test('an animated trim path draws every frame', () async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/Tests/AnimatedTrimPath.json').readAsBytesSync(),
    );
    expect(composition.durationFrames, greaterThan(0));

    var drawable = LottieDrawable(composition);
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    for (var progress = 0; progress <= 100; progress += 5) {
      drawable
        ..setProgress(progress / 100)
        ..draw(canvas, const Rect.fromLTWH(0, 0, 280, 280));
    }
    recorder.endRecording().dispose();
  });
}
