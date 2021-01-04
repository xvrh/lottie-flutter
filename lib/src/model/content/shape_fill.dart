import 'dart:ui';
import '../../animation/content/content.dart';
import '../../animation/content/fill_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_color_value.dart';
import '../animatable/animatable_integer_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

class ShapeFill implements ContentModel {
  final bool fillEnabled;
  final PathFillType fillType;
  final String? name;
  final AnimatableColorValue? color;
  final AnimatableIntegerValue? opacity;
  final bool hidden;

  ShapeFill(
      {required this.fillEnabled,
      required this.fillType,
      this.name,
      this.color,
      this.opacity,
      required this.hidden});

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return FillContent(drawable, layer, this);
  }

  @override
  String toString() {
    return 'ShapeFill{'
        'color='
        ', fillEnabled=$fillEnabled'
        '}';
  }
}
