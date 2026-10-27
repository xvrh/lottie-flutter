import 'dart:ui';
import '../../animation/keyframe/color_keyframe_animation.dart';
import 'base_animatable_value.dart';

class AnimatableColorValue extends BaseAnimatableValue<Color, Color> {
  AnimatableColorValue.fromKeyframes(super.keyframes) : super.fromKeyframes();

  @override
  ColorKeyframeAnimation createAnimation() {
    return ColorKeyframeAnimation(keyframes);
  }
}
