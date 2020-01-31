import 'dart:ui';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/shape_keyframe_animation.dart';
import '../../value/keyframe.dart';
import '../content/shape_data.dart';
import 'base_animatable_value.dart';

class AnimatableShapeValue extends BaseAnimatableValue<ShapeData, Path> {
  AnimatableShapeValue.fromKeyframes(List<Keyframe<ShapeData>> keyframes)
      : super.fromKeyframes(keyframes);

  @override
  BaseKeyframeAnimation<ShapeData, Path> createAnimation() {
    return ShapeKeyframeAnimation(keyframes);
  }
}
