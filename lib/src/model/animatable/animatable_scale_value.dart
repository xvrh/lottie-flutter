import 'dart:ui';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/point_keyframe_animation.dart';
import '../../value/keyframe.dart';
import 'base_animatable_value.dart';

class AnimatableScaleValue extends BaseAnimatableValue<Offset, Offset> {
  AnimatableScaleValue.one() : this(const Offset(1, 1));

  AnimatableScaleValue(Offset value) : super.fromValue(value);

  AnimatableScaleValue.fromKeyframes(List<Keyframe<Offset>> keyframes)
      : super.fromKeyframes(keyframes);

  @override
  BaseKeyframeAnimation<Offset, Offset> createAnimation() {
    return PointKeyframeAnimation(keyframes);
  }
}
