import 'dart:ui';
import '../../animation/keyframe/color_keyframe_animation.dart';
import '../../value/keyframe.dart';
import 'base_animatable_value.dart';

class AnimatableColorValue extends BaseAnimatableValue<Color, Color> {
  AnimatableColorValue.fromKeyframes(List<Keyframe<Color>> keyframes)
      : super.fromKeyframes(keyframes);

  @override
  ColorKeyframeAnimation createAnimation() {
    return ColorKeyframeAnimation(keyframes);
  }
}
