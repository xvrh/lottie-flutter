import 'package:lottie/src/model/animatable/animatable_color_value.dart';
import 'package:lottie/src/model/animatable/animatable_double_value.dart';

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
}
