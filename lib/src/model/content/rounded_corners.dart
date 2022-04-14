import '../../animation/content/content.dart';
import '../../animation/content/rounded_corners_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

class RoundedCorners implements ContentModel {
  final String name;
  final AnimatableValue<double, double> cornerRadius;

  RoundedCorners(this.name, this.cornerRadius);

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return RoundedCornersContent(drawable, layer, this);
  }
}
