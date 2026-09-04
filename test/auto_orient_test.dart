import 'dart:io';
import 'dart:math';

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/animation/keyframe/path_keyframe.dart';
import 'package:lottie/src/animation/keyframe/transform_keyframe_animation.dart';
import 'package:lottie/src/composition.dart';
import 'package:lottie/src/model/animatable/animatable_double_value.dart';
import 'package:lottie/src/model/animatable/animatable_path_value.dart';
import 'package:lottie/src/model/animatable/animatable_transform.dart';
import 'package:lottie/src/value/keyframe.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

void main() {
  late LottieComposition composition;

  setUpAll(() async {
    composition = await LottieComposition.fromBytes(
      File('example/assets/Tests/AutoOrient.json').readAsBytesSync(),
    );
  });

  double angleOf(Matrix4 matrix) => atan2(matrix.storage[1], matrix.storage[0]);

  TransformKeyframeAnimation autoOrientTransform(
    Offset from,
    Offset to, {
    double? rotation,
  }) {
    var keyframe = PathKeyframe(
      composition,
      Keyframe<Offset>(
        composition,
        startValue: from,
        endValue: to,
        interpolator: Curves.linear,
        startFrame: composition.startFrame,
        endFrame: composition.endFrame,
      ),
    );
    var transform = AnimatableTransform(
      position: AnimatablePathValue.fromKeyframes([keyframe]),
      rotation: rotation == null
          ? null
          : AnimatableDoubleValue.fromKeyframes([
              Keyframe.nonAnimated(rotation),
            ]),
    )..isAutoOrient = true;
    return transform.createAnimation();
  }

  test('auto-orient rotates by the tangent angle expressed in radians', () {
    var animation = autoOrientTransform(Offset.zero, const Offset(100, 100))
      ..setProgress(0.5);

    expect(angleOf(animation.getMatrix()), closeTo(pi / 4, 0.01));
  });

  test('the rotation property is applied on top of the auto-orient angle', () {
    var animation = autoOrientTransform(
      Offset.zero,
      const Offset(100, 100),
      rotation: 90,
    )..setProgress(0.5);

    expect(angleOf(animation.getMatrix()), closeTo(pi / 4 + pi / 2, 0.01));
  });

  test('auto-orient of a horizontal movement does not rotate', () {
    var animation = autoOrientTransform(Offset.zero, const Offset(100, 0))
      ..setProgress(0.5);

    expect(angleOf(animation.getMatrix()), closeTo(0, 0.01));
  });

  test('auto-orient stays continuous over the whole animation', () {
    var animation = autoOrientTransform(Offset.zero, const Offset(100, 100));

    var previous = 0.0;
    for (var progress = 0.0; progress < 1; progress += 0.05) {
      animation.setProgress(progress);
      var angle = angleOf(animation.getMatrix());
      expect(angle.abs(), lessThanOrEqualTo(pi));
      if (progress > 0) {
        expect(
          (angle - previous).abs(),
          lessThan(0.1),
          reason: 'the layer must not spin between consecutive frames',
        );
      }
      previous = angle;
    }
  });
}
