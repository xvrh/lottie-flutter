import 'animatable_color_value.dart';
import 'animatable_double_value.dart';

class AnimatableTextProperties {
  final AnimatableColorValue? color;
  final AnimatableColorValue? stroke;
  final AnimatableDoubleValue? strokeWidth;
  final AnimatableDoubleValue? tracking;

  AnimatableTextProperties(
      {this.color, this.stroke, this.strokeWidth, this.tracking});
}
