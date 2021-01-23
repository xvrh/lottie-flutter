import 'dart:ui';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class PointKeyframeAnimation extends KeyframeAnimation<Offset> {
  PointKeyframeAnimation(List<Keyframe<Offset>> keyframes) : super(keyframes);

  @override
  Offset getValue(Keyframe<Offset> keyframe, double keyframeProgress) {
    if (keyframe.startValue == null || keyframe.endValue == null) {
      throw Exception('Missing values for keyframe.');
    }

    var startPoint = keyframe.startValue;
    var endPoint = keyframe.endValue;

    if (valueCallback != null) {
      var value = valueCallback!.getValueInternal(
          keyframe.startFrame,
          keyframe.endFrame,
          startPoint,
          endPoint,
          keyframeProgress,
          getLinearCurrentKeyframeProgress(),
          progress);
      if (value != null) {
        return value;
      }
    }

    return Offset.lerp(startPoint, endPoint, keyframeProgress)!;
  }
}
