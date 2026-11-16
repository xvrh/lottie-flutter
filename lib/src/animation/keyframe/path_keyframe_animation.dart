import 'dart:ui';

import '../../value/keyframe.dart';
import 'keyframe_animation.dart';
import 'path_keyframe.dart';

class PathKeyframeAnimation extends KeyframeAnimation<Offset> {
  PathKeyframe? _pathMeasureKeyframe;
  late PathMetric _pathMeasure;

  PathKeyframeAnimation(super.keyframes, {super.loop});

  @override
  Offset getValue(Keyframe<Offset> keyframe, double keyframeProgress) {
    var pathKeyframe = keyframe as PathKeyframe;
    if (pathKeyframe.getPath() == null) {
      return keyframe.startValue!;
    }

    if (valueCallback != null) {
      var value = getValueFromCallback(
        pathKeyframe.startFrame,
        pathKeyframe.endFrame,
        pathKeyframe.startValue,
        pathKeyframe.endValue,
        getLinearCurrentKeyframeProgress(),
        keyframeProgress,
      );
      if (value != null) {
        return value;
      }
    }

    return getLoopValue(keyframe, keyframeProgress, keyframeProgress);
  }

  @override
  Offset getLoopValue(
    Keyframe<Offset> keyframe,
    double xProgress,
    double yProgress,
  ) {
    var pathKeyframe = keyframe as PathKeyframe;
    var path = pathKeyframe.getPath();
    if (path == null) {
      return keyframe.startValue!;
    }

    if (_pathMeasureKeyframe != pathKeyframe) {
      _pathMeasure = path.computeMetrics().toList().first;
      _pathMeasureKeyframe = pathKeyframe;
    }

    var length = _pathMeasure.length;

    // allow bounce easings to calculate positions outside the path
    // by using the tangent at the extremities

    if (xProgress < 0) {
      var tangent = _pathMeasure.getTangentForOffset(0)!;
      return tangent.position + tangent.vector * (xProgress * length);
    } else if (xProgress > 1) {
      var tangent = _pathMeasure.getTangentForOffset(length)!;
      return tangent.position + tangent.vector * ((xProgress - 1) * length);
    } else {
      return _pathMeasure.getTangentForOffset(xProgress * length)!.position;
    }
  }
}
