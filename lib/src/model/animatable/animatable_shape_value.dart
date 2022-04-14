import 'dart:ui';
import '../../animation/keyframe/shape_keyframe_animation.dart';
import '../../value/keyframe.dart';
import '../content/shape_data.dart';
import 'base_animatable_value.dart';

class AnimatableShapeValue extends BaseAnimatableValue<ShapeData, Path> {
  AnimatableShapeValue.fromKeyframes(List<Keyframe<ShapeData>> keyframes)
      : super.fromKeyframes(keyframes);

  @override
  ShapeKeyframeAnimation createAnimation() {
    return ShapeKeyframeAnimation(keyframes);
  }
}
