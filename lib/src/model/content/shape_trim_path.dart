import '../../animation/content/content.dart';
import '../../animation/content/trim_path_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_double_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

enum ShapeTrimPathType { simultaneously, individually }

class ShapeTrimPath implements ContentModel {
  final String? name;
  final ShapeTrimPathType type;
  final AnimatableDoubleValue start;
  final AnimatableDoubleValue end;
  final AnimatableDoubleValue offset;
  final bool hidden;

  ShapeTrimPath({
    this.name,
    required this.type,
    required this.start,
    required this.end,
    required this.offset,
    required this.hidden,
  });

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return TrimPathContent(layer, this);
  }

  @override
  String toString() {
    return 'Trim Path: {start: $start, end: $end, offset: $offset}';
  }

  static ShapeTrimPathType typeForId(int id) {
    switch (id) {
      case 1:
        return ShapeTrimPathType.simultaneously;
      case 2:
        return ShapeTrimPathType.individually;
      default:
        throw Exception('Unknown trim path type $id');
    }
  }
}
