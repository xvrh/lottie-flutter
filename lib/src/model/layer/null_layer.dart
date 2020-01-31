import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../lottie_drawable.dart';
import 'base_layer.dart';
import 'layer.dart';

class NullLayer extends BaseLayer {
  NullLayer(LottieDrawable lottieDrawable, Layer layerModel)
      : super(lottieDrawable, layerModel);

  @override
  void drawLayer(Canvas canvas, Size size, Matrix4 parentMatrix,
      {int parentAlpha}) {
    // Do nothing.
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {bool applyParents}) {
    super.getBounds(parentMatrix, applyParents: applyParents);
    return Rect.zero;
  }
}
