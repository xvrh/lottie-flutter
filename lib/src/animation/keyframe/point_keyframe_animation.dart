import 'dart:ui';

import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class PointKeyframeAnimation extends KeyframeAnimation<Offset> {
  PointKeyframeAnimation(super.keyframes, {super.loop});

  @override
  Offset getValue(Keyframe<Offset> keyframe, double keyframeProgress) {
    return getValueSplitDimension(
      keyframe,
      keyframeProgress,
      keyframeProgress,
      keyframeProgress,
    );
  }

  @override
  Offset getValueSplitDimension(
    Keyframe<Offset> keyframe,
    double linearKeyframeProgress,
    double xKeyframeProgress,
    double yKeyframeProgress,
  ) {
    if (keyframe.startValue == null || keyframe.endValue == null) {
      throw Exception('Missing values for keyframe.');
    }

    var startPoint = keyframe.startValue!;
    var endPoint = keyframe.endValue!;

    if (valueCallback != null) {
      var value = getValueFromCallback(
        keyframe.startFrame,
        keyframe.endFrame,
        startPoint,
        endPoint,
        linearKeyframeProgress,
        getLinearCurrentKeyframeProgress(),
      );
      if (value != null) {
        return value;
      }
    }

    return getLoopValue(keyframe, xKeyframeProgress, yKeyframeProgress);
  }

  @override
  Offset getLoopValue(
    Keyframe<Offset> keyframe,
    double xProgress,
    double yProgress,
  ) {
    var startPoint = keyframe.startValue!;
    var endPoint = keyframe.endValue!;
    return Offset(
      startPoint.dx + xProgress * (endPoint.dx - startPoint.dx),
      startPoint.dy + yProgress * (endPoint.dy - startPoint.dy),
    );
  }
}
