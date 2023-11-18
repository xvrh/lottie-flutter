import 'dart:math' as math;
import 'dart:ui';
import '../../model/content/gradient_color.dart';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class GradientColorKeyframeAnimation extends KeyframeAnimation<GradientColor> {
  late GradientColor _gradientColor;

  GradientColorKeyframeAnimation(List<Keyframe<GradientColor>> keyframes)
      : super(keyframes) {
    // Not all keyframes that this GradientColor are used for will have the same length.
    // AnimatableGradientColorValue.ensureInterpolatableKeyframes may add extra positions
    // for some keyframes but not others to ensure that it is interpolatable.
    // Ensure that there is enough space for the largest keyframe.
    var size = 0;
    for (var i = 0; i < keyframes.length; i++) {
      var startValue = keyframes[i].startValue;
      if (startValue != null) {
        size = math.max(size, startValue.size);
      }
    }
    _gradientColor = GradientColor(List<double>.filled(size, 0.0),
        List<Color>.filled(size, const Color(0x00000000)));
  }

  @override
  GradientColor getValue(
      Keyframe<GradientColor> keyframe, double keyframeProgress) {
    _gradientColor.lerp(
        keyframe.startValue!, keyframe.endValue!, keyframeProgress);
    return _gradientColor;
  }
}
