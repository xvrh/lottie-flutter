import 'dart:ui';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class IntegerKeyframeAnimation extends KeyframeAnimation<int> {
  IntegerKeyframeAnimation(List<Keyframe<int>> keyframes) : super(keyframes);

  @override
  int getValue(Keyframe<int> keyframe, double keyframeProgress) {
    if (keyframe.startValue == null || keyframe.endValue == null) {
      throw Exception('Missing values for keyframe.');
    }

    if (valueCallback != null) {
      var value = valueCallback!.getValueInternal(
          keyframe.startFrame,
          keyframe.endFrame,
          keyframe.startValue,
          keyframe.endValue,
          keyframeProgress,
          getLinearCurrentKeyframeProgress(),
          progress);
      if (value != null) {
        return value;
      }
    }

    return lerpDouble(keyframe.startValue, keyframe.endValue, keyframeProgress)!
        .round();
  }
}
