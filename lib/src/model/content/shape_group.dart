import '../../animation/content/content.dart';
import '../../animation/content/content_group.dart';
import '../../lottie_drawable.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

class ShapeGroup implements ContentModel {
  final String? name;
  final List<ContentModel> items;
  final bool hidden;

  ShapeGroup(this.name, this.items, {required this.hidden});

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return ContentGroup(drawable, layer, this);
  }

  @override
  String toString() {
    return "ShapeGroup{name: '$name' Shapes: $items}";
  }
}
