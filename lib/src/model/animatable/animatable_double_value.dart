import '../../animation/keyframe/double_keyframe_animation.dart';
import 'base_animatable_value.dart';

class AnimatableDoubleValue extends BaseAnimatableValue<double, double> {
  AnimatableDoubleValue() : super.fromValue(0.0);

  AnimatableDoubleValue.fromKeyframes(super.keyframes) : super.fromKeyframes();

  @override
  DoubleKeyframeAnimation createAnimation() {
    return DoubleKeyframeAnimation(keyframes);
  }
}
