import 'dart:ui';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class PointKeyframeAnimation extends KeyframeAnimation<Offset> {
  PointKeyframeAnimation(super.keyframes);

  @override
  Offset getValue(Keyframe<Offset> keyframe, double keyframeProgress) {
    return getValueSplitDimension(
        keyframe, keyframeProgress, keyframeProgress, keyframeProgress);
  }

  @override
  Offset getValueSplitDimension(
      Keyframe<Offset> keyframe,
      double linearKeyframeProgress,
      double xKeyframeProgress,
      double yKeyframeProgress) {
    if (keyframe.startValue == null || keyframe.endValue == null) {
      throw Exception('Missing values for keyframe.');
    }

    var startPoint = keyframe.startValue!;
    var endPoint = keyframe.endValue!;

    if (valueCallback != null) {
      var value = valueCallback!.getValueInternal(
          keyframe.startFrame,
          keyframe.endFrame,
          startPoint,
          endPoint,
          linearKeyframeProgress,
          getLinearCurrentKeyframeProgress(),
          progress);
      if (value != null) {
        return value;
      }
    }

    return Offset(
        startPoint.dx + xKeyframeProgress * (endPoint.dx - startPoint.dx),
        startPoint.dy + yKeyframeProgress * (endPoint.dy - startPoint.dy));
  }
}
