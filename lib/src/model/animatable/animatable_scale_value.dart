import 'dart:ui';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/point_keyframe_animation.dart';
import 'base_animatable_value.dart';

class AnimatableScaleValue extends BaseAnimatableValue<Offset, Offset> {
  AnimatableScaleValue.one() : this(const Offset(1, 1));

  AnimatableScaleValue(super.value) : super.fromValue();

  AnimatableScaleValue.fromKeyframes(super.keyframes) : super.fromKeyframes();

  @override
  BaseKeyframeAnimation<Offset, Offset> createAnimation() {
    return PointKeyframeAnimation(keyframes);
  }
}
