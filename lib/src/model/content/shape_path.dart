import '../../animation/content/content.dart';
import '../../animation/content/shape_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_shape_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

class ShapePath implements ContentModel {
  final String? name;
  final int index;
  final AnimatableShapeValue shapePath;
  final bool hidden;

  ShapePath({
    this.name,
    required this.index,
    required this.shapePath,
    required this.hidden,
  });

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return ShapeContent(drawable, layer, this);
  }

  @override
  String toString() {
    return 'ShapePath{name=$name, index=$index}';
  }
}
