import 'dart:ui';
import '../../model/content/gradient_color.dart';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class GradientColorKeyframeAnimation extends KeyframeAnimation<GradientColor> {
  late GradientColor _gradientColor;

  GradientColorKeyframeAnimation(List<Keyframe<GradientColor>> keyframes)
      : super(keyframes) {
    var startValue = keyframes.first.startValue;
    var size = startValue == null ? 0 : startValue.size;
    _gradientColor = GradientColor(
        List<double>.filled(size, 0.0), List<Color>.filled(size, Color(0)));
  }

  @override
  GradientColor getValue(
      Keyframe<GradientColor> keyframe, double keyframeProgress) {
    _gradientColor.lerp(
        keyframe.startValue!, keyframe.endValue!, keyframeProgress);
    return _gradientColor;
  }
}
