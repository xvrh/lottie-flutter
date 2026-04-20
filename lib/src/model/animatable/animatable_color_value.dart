import 'dart:ui';
import 'package:meta/meta.dart';
import '../../animation/keyframe/color_keyframe_animation.dart';
import 'base_animatable_value.dart';

class AnimatableColorValue extends BaseAnimatableValue<Color, Color> {
  AnimatableColorValue.fromKeyframes(super.keyframes) : super.fromKeyframes();

  /// Slot id from the property object's `"sid"` field, if present.
  /// Cleared after root color slots are applied during composition parsing.
  @internal
  String? slotId;

  @override
  ColorKeyframeAnimation createAnimation() {
    return ColorKeyframeAnimation(keyframes);
  }
}
