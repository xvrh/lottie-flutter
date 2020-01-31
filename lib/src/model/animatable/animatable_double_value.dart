import '../../animation/keyframe/double_keyframe_animation.dart';
import '../../value/keyframe.dart';
import 'base_animatable_value.dart';

class AnimatableDoubleValue extends BaseAnimatableValue<double, double> {
  AnimatableDoubleValue() : super.fromValue(0.0);

  AnimatableDoubleValue.fromKeyframes(List<Keyframe<double>> keyframes)
      : super.fromKeyframes(keyframes);

  @override
  DoubleKeyframeAnimation createAnimation() {
    return DoubleKeyframeAnimation(keyframes);
  }
}
