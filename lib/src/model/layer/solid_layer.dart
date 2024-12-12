import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/value_callback_keyframe_animation.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../utils.dart';
import '../../value/lottie_value_callback.dart';
import 'base_layer.dart';
import 'layer.dart';

class SolidLayer extends BaseLayer {
  final Paint paint = Paint()..style = PaintingStyle.fill;
  final Path path = Path();
  BaseKeyframeAnimation<ColorFilter, ColorFilter?>? _colorFilterAnimation;
  BaseKeyframeAnimation<Color, Color?>? _colorAnimation;

  SolidLayer(LottieDrawable lottieDrawable, Layer layerModel)
      : super(lottieDrawable, layerModel) {
    paint.color = layerModel.solidColor.withAlpha(0);
  }

  @override
  void drawLayer(Canvas canvas, Matrix4 parentMatrix,
      {required int parentAlpha}) {
    var backgroundAlpha = layerModel.solidColor.a;
    if (backgroundAlpha == 0) {
      return;
    }

    paint.color = _colorAnimation?.value ?? layerModel.solidColor;

    var opacity = transform.opacity?.value ?? 100;
    var alpha =
        (parentAlpha / 255.0 * (backgroundAlpha * opacity / 100.0) * 255.0)
            .round();
    paint.setAlpha(alpha);

    if (_colorFilterAnimation != null) {
      paint.colorFilter = _colorFilterAnimation!.value;
    }
    if (alpha > 0) {
      var points = List<double>.filled(8, 0.0);
      points[2] = points[4] = layerModel.solidWidth.toDouble();
      points[5] = points[7] = layerModel.solidHeight.toDouble();

      // We can't map rect here because if there is rotation on the transform then we aren't
      // actually drawing a rect.
      parentMatrix.mapPoints(points);
      path.reset();
      path.moveTo(points[0], points[1]);
      path.lineTo(points[2], points[3]);
      path.lineTo(points[4], points[5]);
      path.lineTo(points[6], points[7]);
      path.lineTo(points[0], points[1]);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    super.getBounds(parentMatrix, applyParents: applyParents);
    var rect = Rect.fromLTWH(0, 0, layerModel.solidWidth.toDouble(),
        layerModel.solidHeight.toDouble());
    rect = boundsMatrix.mapRect(rect);
    return rect;
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    super.addValueCallback(property, callback);
    if (property == LottieProperty.colorFilter) {
      if (callback == null) {
        _colorFilterAnimation = null;
      } else {
        _colorFilterAnimation = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<ColorFilter>, null);
      }
    } else if (property == LottieProperty.color) {
      if (callback == null) {
        _colorAnimation = null;
        paint.color = layerModel.solidColor;
      } else {
        _colorAnimation = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<Color>, null);
      }
    }
  }
}
