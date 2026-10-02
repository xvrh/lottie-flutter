import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('Frame rate round', () async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/LottieLogo1.json').readAsBytesSync(),
    );
    expect(composition.roundProgress(0, frameRate: FrameRate.composition), 0);
    expect(
      composition.roundProgress(0.0001, frameRate: FrameRate.composition),
      0,
    );
    expect(composition.roundProgress(0.0001, frameRate: FrameRate.max), 0.0001);
  });

  test('Frame rate round samples the exact frame', () async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/LottieLogo1.json').readAsBytesSync(),
    );
    // `durationFrames` excludes the 0.01 offset applied to the end frame.
    var frameCount = (composition.durationFrames + 0.01).round();

    for (var i = 0; i < frameCount; i++) {
      var progress = composition.roundProgress(
        (i + 0.5) / frameCount,
        frameRate: FrameRate.composition,
      );
      var frame =
          composition.startFrame + progress * composition.durationFrames;
      expect(frame, closeTo(composition.startFrame + i, 1e-9), reason: '$i');
    }

    // At half the frame rate, only every other frame is sampled.
    var halfFrameRate = FrameRate(composition.frameRate / 2);
    for (var i = 0; i < frameCount ~/ 2; i++) {
      var progress = composition.roundProgress(
        (i + 0.5) / (frameCount / 2),
        frameRate: halfFrameRate,
      );
      var frame =
          composition.startFrame + progress * composition.durationFrames;
      expect(
        frame,
        closeTo(composition.startFrame + 2 * i, 1e-9),
        reason: '$i',
      );
    }

    expect(
      composition.roundProgress(1, frameRate: FrameRate.composition),
      lessThanOrEqualTo(1),
    );
  });
}
