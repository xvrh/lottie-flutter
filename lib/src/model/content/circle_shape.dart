import 'dart:ui';
import '../../animation/content/content.dart';
import '../../animation/content/ellipse_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_point_value.dart';
import '../animatable/animatable_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

class CircleShape implements ContentModel {
  final String name;
  final AnimatableValue<Offset, Offset> position;
  final AnimatablePointValue size;
  final bool isReversed;
  final bool hidden;

  CircleShape(
      {this.name, this.position, this.size, this.isReversed, this.hidden});

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return EllipseContent(drawable, layer, this);
  }
}
