import 'dart:ui';
import '../../animation/keyframe/point_keyframe_animation.dart';
import 'base_animatable_value.dart';

class AnimatablePointValue extends BaseAnimatableValue<Offset, Offset> {
  AnimatablePointValue.fromKeyframes(super.keyframes) : super.fromKeyframes();

  @override
  PointKeyframeAnimation createAnimation() {
    return PointKeyframeAnimation(keyframes);
  }
}
