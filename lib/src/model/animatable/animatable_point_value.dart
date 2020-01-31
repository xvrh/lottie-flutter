import 'dart:ui';
import '../../animation/keyframe/point_keyframe_animation.dart';
import '../../value/keyframe.dart';
import 'base_animatable_value.dart';

class AnimatablePointValue extends BaseAnimatableValue<Offset, Offset> {
  AnimatablePointValue.fromKeyframes(List<Keyframe<Offset>> keyframes)
      : super.fromKeyframes(keyframes);

  @override
  PointKeyframeAnimation createAnimation() {
    return PointKeyframeAnimation(keyframes);
  }
}
