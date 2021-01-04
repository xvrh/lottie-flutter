import '../../animation/content/content.dart';
import '../../animation/content/gradient_stroke_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_double_value.dart';
import '../animatable/animatable_gradient_color_value.dart';
import '../animatable/animatable_integer_value.dart';
import '../animatable/animatable_point_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';
import 'gradient_type.dart';
import 'shape_stroke.dart';

class GradientStroke implements ContentModel {
  final String? name;
  final GradientType gradientType;
  final AnimatableGradientColorValue gradientColor;
  final AnimatableIntegerValue opacity;
  final AnimatablePointValue startPoint;
  final AnimatablePointValue endPoint;
  final AnimatableDoubleValue width;
  final LineCapType? capType;
  final LineJoinType? joinType;
  final double miterLimit;
  final List<AnimatableDoubleValue> lineDashPattern;
  final AnimatableDoubleValue? dashOffset;
  final bool hidden;

  GradientStroke({
    this.name,
    required this.gradientType,
    required this.gradientColor,
    required this.opacity,
    required this.startPoint,
    required this.endPoint,
    required this.width,
    this.capType,
    this.joinType,
    required this.miterLimit,
    required this.lineDashPattern,
    this.dashOffset,
    required this.hidden,
  });

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return GradientStrokeContent(drawable, layer, this);
  }
}
