import 'package:flutter/painting.dart';
import '../../value/keyframe.dart';
import '../animatable/animatable_color_value.dart';
import '../animatable/animatable_double_value.dart';

class DropShadowEffect {
  final AnimatableColorValue color;
  final AnimatableDoubleValue opacity;
  final AnimatableDoubleValue direction;
  final AnimatableDoubleValue distance;
  final AnimatableDoubleValue radius;

  DropShadowEffect({
    required this.color,
    required this.opacity,
    required this.direction,
    required this.distance,
    required this.radius,
  });

  static DropShadowEffect createEmpty() => DropShadowEffect(
    color: AnimatableColorValue.fromKeyframes([
      Keyframe.nonAnimated(const Color(0x00000000)),
    ]),
    direction: AnimatableDoubleValue(),
    radius: AnimatableDoubleValue(),
    distance: AnimatableDoubleValue(),
    opacity: AnimatableDoubleValue(),
  );
}
