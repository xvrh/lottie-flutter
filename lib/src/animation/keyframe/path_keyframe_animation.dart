import 'dart:ui';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';
import 'path_keyframe.dart';

class PathKeyframeAnimation extends KeyframeAnimation<Offset> {
  PathKeyframe? _pathMeasureKeyframe;
  late PathMetric _pathMeasure;

  PathKeyframeAnimation(List<Keyframe<Offset>> keyframes) : super(keyframes);

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

    return _pathMeasure
        .getTangentForOffset(keyframeProgress * _pathMeasure.length)!
        .position;
  }
}
