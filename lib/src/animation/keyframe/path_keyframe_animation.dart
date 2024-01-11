import 'dart:ui';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';
import 'path_keyframe.dart';

class PathKeyframeAnimation extends KeyframeAnimation<Offset> {
  PathKeyframe? _pathMeasureKeyframe;
  late PathMetric _pathMeasure;

  PathKeyframeAnimation(super.keyframes);

  @override
  Offset getValue(Keyframe<Offset> keyframe, double keyframeProgress) {
    var pathKeyframe = keyframe as PathKeyframe;
    var path = pathKeyframe.getPath();
    if (path == null) {
      return keyframe.startValue!;
    }

    if (valueCallback != null) {
      var value = valueCallback!.getValueInternal(
          pathKeyframe.startFrame,
          pathKeyframe.endFrame,
          pathKeyframe.startValue,
          pathKeyframe.endValue,
          getLinearCurrentKeyframeProgress(),
          keyframeProgress,
          progress);
      if (value != null) {
        return value;
      }
    }

    if (_pathMeasureKeyframe != pathKeyframe) {
      _pathMeasure = path.computeMetrics().toList().first;
      _pathMeasureKeyframe = pathKeyframe;
    }

    var length = _pathMeasure.length;

    // allow bounce easings to calculate positions outside the path
    // by using the tangent at the extremities

    if (keyframeProgress < 0) {
      var tangent = _pathMeasure.getTangentForOffset(0)!;
      return tangent.position + tangent.vector * (keyframeProgress * length);
    } else if (keyframeProgress > 1) {
      var tangent = _pathMeasure.getTangentForOffset(length)!;
      return tangent.position +
          tangent.vector * ((keyframeProgress - 1) * length);
    } else {
      return _pathMeasure
          .getTangentForOffset(keyframeProgress * length)!
          .position;
    }
  }
}
