import '../../value/keyframe.dart';
import '../../value/scale_xy.dart';
import 'keyframe_animation.dart';

class ScaleKeyframeAnimation extends KeyframeAnimation<ScaleXY> {
  ScaleKeyframeAnimation(List<Keyframe<ScaleXY>> keyframes) : super(keyframes);

  @override
  ScaleXY getValue(Keyframe<ScaleXY> keyframe, double keyframeProgress) {
    if (keyframe.startValue == null || keyframe.endValue == null) {
      throw StateError('Missing values for keyframe.');
    }
    var startTransform = keyframe.startValue;
    var endTransform = keyframe.endValue;

    if (valueCallback != null) {
      var value = valueCallback.getValueInternal(
          keyframe.startFrame,
          keyframe.endFrame,
          startTransform,
          endTransform,
          keyframeProgress,
          getLinearCurrentKeyframeProgress(),
          progress);
      if (value != null) {
        return value;
      }
    }

    return ScaleXY.lerp(startTransform, endTransform, keyframeProgress);
  }
}
