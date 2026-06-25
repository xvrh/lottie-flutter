import 'animatable_color_value.dart';
import 'animatable_double_value.dart';
import 'animatable_integer_value.dart';

class AnimatableTextStyle {
  final AnimatableColorValue? color;
  final AnimatableColorValue? stroke;
  final AnimatableDoubleValue? strokeWidth;
  final AnimatableDoubleValue? tracking;
  final AnimatableIntegerValue? opacity;

  AnimatableTextStyle({
    this.color,
    this.stroke,
    this.strokeWidth,
    this.tracking,
    this.opacity,
  });
}
