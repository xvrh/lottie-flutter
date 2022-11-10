import 'dart:ui';
import '../../utils/gamma_evaluator.dart';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class ColorKeyframeAnimation extends KeyframeAnimation<Color> {
  ColorKeyframeAnimation(super.keyframes);

  @override
  Color getValue(Keyframe<Color> keyframe, double keyframeProgress) {
    if (keyframe.startValue == null || keyframe.endValue == null) {
      throw Exception('Missing values for keyframe.');
    }
    var startColor = keyframe.startValue;
    var endColor = keyframe.endValue;

    if (valueCallback != null) {
      var value = valueCallback!.getValueInternal(
          keyframe.startFrame,
          keyframe.endFrame,
          startColor,
          endColor,
          keyframeProgress,
          getLinearCurrentKeyframeProgress(),
          progress);
      if (value != null) {
        return value;
      }
    }

    return GammaEvaluator.evaluate(
        keyframeProgress.clamp(0, 1).toDouble(), startColor!, endColor!);
  }
}
