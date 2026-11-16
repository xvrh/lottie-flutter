import 'dart:ui';

import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class IntegerKeyframeAnimation extends KeyframeAnimation<int> {
  IntegerKeyframeAnimation(super.keyframes, {super.loop});

  @override
  int getValue(Keyframe<int> keyframe, double keyframeProgress) {
    if (keyframe.startValue == null) {
      throw Exception('Missing values for keyframe.');
    }

    var endValue = keyframe.endValue ?? keyframe.startValue;

    if (valueCallback != null) {
      var value = getValueFromCallback(
        keyframe.startFrame,
        keyframe.endFrame,
        keyframe.startValue,
        endValue,
        keyframeProgress,
        getLinearCurrentKeyframeProgress(),
      );
      if (value != null) {
        return value;
      }
    }

    return getLoopValue(keyframe, keyframeProgress, keyframeProgress).round();
  }

  @override
  double getLoopValue(
    Keyframe<int> keyframe,
    double xProgress,
    double yProgress,
  ) {
    var startValue = keyframe.startValue!;
    var endValue = keyframe.endValue ?? startValue;
    return lerpDouble(startValue, endValue, xProgress)!;
  }
}
