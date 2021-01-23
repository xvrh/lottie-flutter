import 'dart:ui';
import '../../animation/content/content.dart';
import '../../animation/content/gradient_fill_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_double_value.dart';
import '../animatable/animatable_gradient_color_value.dart';
import '../animatable/animatable_integer_value.dart';
import '../animatable/animatable_point_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';
import 'gradient_type.dart';

class GradientFill implements ContentModel {
  final String? name;
  final GradientType gradientType;
  final PathFillType fillType;
  final AnimatableGradientColorValue gradientColor;
  final AnimatableIntegerValue opacity;
  final AnimatablePointValue startPoint;
  final AnimatablePointValue endPoint;
  final AnimatableDoubleValue? highlightLength;
  final AnimatableDoubleValue? highlightAngle;
  final bool hidden;

  GradientFill({
    this.name,
    required this.gradientType,
    required this.fillType,
    required this.gradientColor,
    required this.opacity,
    required this.startPoint,
    required this.endPoint,
    this.highlightLength,
    this.highlightAngle,
    required this.hidden,
  });

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return GradientFillContent(drawable, layer, this);
  }
}
