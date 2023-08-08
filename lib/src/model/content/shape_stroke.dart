import 'dart:ui' as ui;
import '../../animation/content/content.dart';
import '../../animation/content/stroke_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_color_value.dart';
import '../animatable/animatable_double_value.dart';
import '../animatable/animatable_integer_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

enum LineCapType { butt, round, unknown }

ui.StrokeCap lineCapTypeToPaintCap(LineCapType? cap) {
  switch (cap) {
    case LineCapType.butt:
      return ui.StrokeCap.butt;
    case LineCapType.round:
      return ui.StrokeCap.round;
    case LineCapType.unknown:
    case null:
      return ui.StrokeCap.butt;
  }
}

enum LineJoinType { miter, round, bevel }

ui.StrokeJoin lineJoinTypeToPaintJoin(LineJoinType? join) {
  switch (join) {
    case LineJoinType.bevel:
      return ui.StrokeJoin.bevel;
    case LineJoinType.round:
      return ui.StrokeJoin.round;
    case LineJoinType.miter:
    case null:
      return ui.StrokeJoin.miter;
  }
}

class ShapeStroke implements ContentModel {
  final String? name;
  final AnimatableDoubleValue? dashOffset;
  final List<AnimatableDoubleValue> lineDashPattern;
  final AnimatableColorValue color;
  final AnimatableIntegerValue opacity;
  final AnimatableDoubleValue width;
  final LineCapType? capType;
  final LineJoinType? joinType;
  final double miterLimit;
  final bool hidden;

  ShapeStroke(
      {this.name,
      this.dashOffset,
      required this.lineDashPattern,
      required this.color,
      required this.opacity,
      required this.width,
      this.capType,
      this.joinType,
      required this.miterLimit,
      required this.hidden});

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return StrokeContent(drawable, layer, this);
  }
}
