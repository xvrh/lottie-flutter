import 'dart:ui';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class IntegerKeyframeAnimation extends KeyframeAnimation<int> {
  IntegerKeyframeAnimation(super.keyframes);

  @override
  int getValue(Keyframe<int> keyframe, double keyframeProgress) {
    if (keyframe.startValue == null) {
      throw Exception('Missing values for keyframe.');
    }

    var endValue = keyframe.endValue ?? keyframe.startValue;

    if (valueCallback != null) {
      var value = valueCallback!.getValueInternal(
          keyframe.startFrame,
          keyframe.endFrame,
          keyframe.startValue,
          endValue,
          keyframeProgress,
          getLinearCurrentKeyframeProgress(),
          progress);
      if (value != null) {
        return value;
      }
    }

    return lerpDouble(keyframe.startValue, endValue, keyframeProgress)!.round();
  }
}
