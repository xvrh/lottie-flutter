import '../animatable/animatable_double_value.dart';

class BlurEffect {
  final AnimatableDoubleValue blurriness;

  /// After Effects Gaussian Blur "Blur Dimensions".
  /// 1 = horizontal and vertical, 2 = horizontal, 3 = vertical.
  final AnimatableDoubleValue? dimensions;

  BlurEffect(this.blurriness, {this.dimensions});
}
