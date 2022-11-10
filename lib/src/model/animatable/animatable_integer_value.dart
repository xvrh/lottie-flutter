import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/integer_keyframe_animation.dart';
import 'base_animatable_value.dart';

class AnimatableIntegerValue extends BaseAnimatableValue<int, int> {
  AnimatableIntegerValue() : super.fromValue(100);

  AnimatableIntegerValue.fromKeyframes(super.keyframes) : super.fromKeyframes();

  @override
  BaseKeyframeAnimation<int, int> createAnimation() {
    return IntegerKeyframeAnimation(keyframes);
  }
}
