import '../../animation/content/content.dart';
import '../../animation/content/repeater_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_double_value.dart';
import '../animatable/animatable_transform.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

class Repeater implements ContentModel {
  final String? name;
  final AnimatableDoubleValue copies;
  final AnimatableDoubleValue offset;
  final AnimatableTransform transform;
  final bool hidden;

  Repeater({
    this.name,
    required this.copies,
    required this.offset,
    required this.transform,
    required this.hidden,
  });

  @override
  Content? toContent(LottieDrawable drawable, BaseLayer layer) {
    return RepeaterContent(drawable, layer, this);
  }
}
