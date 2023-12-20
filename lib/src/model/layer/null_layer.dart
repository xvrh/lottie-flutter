import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import 'base_layer.dart';

class NullLayer extends BaseLayer {
  NullLayer(super.lottieDrawable, super.layerModel);

  @override
  void drawLayer(Canvas canvas, Matrix4 parentMatrix,
      {required int parentAlpha}) {
    // Do nothing.
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    super.getBounds(parentMatrix, applyParents: applyParents);
    return Rect.zero;
  }
}
