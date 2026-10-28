import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
    for (var composition in await _compositions()) {
      // `durationFrames` excludes the 0.01 offset applied to the end frame.
      var frameCount = (composition.durationFrames + 0.01).round();
      // At half the frame rate, only every other frame is sampled.
      for (var step in [1, 2]) {
        var frameRate = FrameRate(composition.frameRate / step);
        for (var i = 0; i <= frameCount; i += step) {
          for (var offset in [0.0, 0.5]) {
            var progress = composition.roundProgress(
              min((i + offset) / frameCount, 1.0),
              frameRate: frameRate,
            );
            var frame =
                composition.startFrame + progress * composition.durationFrames;
            expect(
              frame,
              closeTo(
                min(composition.startFrame + i, composition.endFrame),
                1e-9,
              ),
              reason: 'frame $i + $offset, $frameRate',
            );
          }
        }
      }
      expect(
        composition.roundProgress(1, frameRate: FrameRate.composition),
        1.0,
      );
    }
  });

  // The widget rounds the progress, then LottieDrawable.setProgress rounds it
  // again: the second rounding must not move to another frame.
  test('Frame rate round is stable when applied twice', () async {
    for (var composition in await _compositions()) {
      for (var frameRate in [
        FrameRate.composition,
        FrameRate(composition.frameRate / 2),
      ]) {
        for (var i = 0; i <= 1000; i++) {
          var rounded = composition.roundProgress(
            i / 1000,
            frameRate: frameRate,
          );
          expect(
            composition.roundProgress(rounded, frameRate: frameRate),
            rounded,
            reason: '${i / 1000}, $frameRate',
          );
        }
      }
    }
  });
}

Future<List<LottieComposition>> _compositions() async => [
  await LottieComposition.fromBytes(
    File('example/assets/LottieLogo1.json').readAsBytesSync(),
  ),
  // 69.99 - 10 + 0.01 is not exactly 60 in floating point.
  await LottieComposition.fromBytes(
    utf8.encode(
      '{"v": "5.7.4", "fr": 60, "ip": 10, "op": 70, "w": 10, "h": 10, "layers": []}',
    ),
  ),
];
