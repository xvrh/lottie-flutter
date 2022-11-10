import '../../animation/keyframe/gradient_color_keyframe_animation.dart';
import '../content/gradient_color.dart';
import 'base_animatable_value.dart';

class AnimatableGradientColorValue
    extends BaseAnimatableValue<GradientColor, GradientColor> {
  AnimatableGradientColorValue.fromKeyframes(super.keyframes)
      : super.fromKeyframes();

  @override
  GradientColorKeyframeAnimation createAnimation() {
    return GradientColorKeyframeAnimation(keyframes);
  }
}
