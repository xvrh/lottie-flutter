import 'dart:ui';
import '../../animation/content/content.dart';
import '../../animation/content/rectangle_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_double_value.dart';
import '../animatable/animatable_point_value.dart';
import '../animatable/animatable_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

class RectangleShape implements ContentModel {
  final String? name;
  final AnimatableValue<Offset, Offset> position;
  final AnimatablePointValue size;
  final AnimatableDoubleValue cornerRadius;
  final bool hidden;

  RectangleShape(
      {this.name,
      required this.position,
      required this.size,
      required this.cornerRadius,
      required this.hidden});

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return RectangleContent(drawable, layer, this);
  }

  @override
  String toString() {
    return 'RectangleShape{position=$position, size=$size}';
  }
}
