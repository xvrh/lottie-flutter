import '../../animation/content/content.dart';
import '../../lottie_drawable.dart';
import '../layer/base_layer.dart';

abstract class ContentModel {
  Content? toContent(LottieDrawable drawable, BaseLayer layer);
}
