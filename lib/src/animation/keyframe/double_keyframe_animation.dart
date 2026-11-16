import 'dart:ui';

import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class DoubleKeyframeAnimation extends KeyframeAnimation<double> {
  DoubleKeyframeAnimation(super.keyframes, {super.loop});

  @override
  double getValue(Keyframe<double> keyframe, double keyframeProgress) {
    if (keyframe.startValue == null || keyframe.endValue == null) {
      throw Exception('Missing values for keyframe.');
    }

    if (valueCallback != null) {
      var value = getValueFromCallback(
        keyframe.startFrame,
        keyframe.endFrame,
        keyframe.startValue,
        keyframe.endValue,
        keyframeProgress,
        getLinearCurrentKeyframeProgress(),
      );
      if (value != null) {
        return value;
      }
    }

    return getLoopValue(keyframe, keyframeProgress, keyframeProgress);
  }

  @override
  double getLoopValue(
    Keyframe<double> keyframe,
    double xProgress,
    double yProgress,
  ) {
    return lerpDouble(keyframe.startValue, keyframe.endValue, xProgress)!;
  }
}
