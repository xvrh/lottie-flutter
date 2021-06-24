import 'dart:ui';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/path_keyframe_animation.dart';
import '../../animation/keyframe/point_keyframe_animation.dart';
import '../../value/keyframe.dart';
import 'animatable_value.dart';

class AnimatablePathValue implements AnimatableValue<Offset, Offset> {
  @override
  final List<Keyframe<Offset>> keyframes;

  /// Create a default static animatable path.
  AnimatablePathValue() : keyframes = [Keyframe.nonAnimated(Offset.zero)];

  AnimatablePathValue.fromKeyframes(this.keyframes);

  @override
  bool get isStatic {
    return keyframes.length == 1 && keyframes[0].isStatic;
  }

  @override
  BaseKeyframeAnimation<Offset, Offset> createAnimation() {
    if (keyframes.first.isStatic) {
      return PointKeyframeAnimation(keyframes);
    }
    return PathKeyframeAnimation(keyframes);
  }
}
