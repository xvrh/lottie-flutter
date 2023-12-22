import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/value_callback_keyframe_animation.dart';
import '../../lottie_property.dart';
import '../../utils.dart';
import '../../value/lottie_value_callback.dart';
import 'base_layer.dart';

class ImageLayer extends BaseLayer {
  final Paint paint = Paint();
  BaseKeyframeAnimation<ColorFilter, ColorFilter?>? _colorFilterAnimation;

  ImageLayer(super.lottieDrawable, super.layerModel);

  @override
  void drawLayer(Canvas canvas, Matrix4 parentMatrix,
      {required int parentAlpha}) {
    var bitmap = getBitmap();
    if (bitmap == null) {
      return;
    }

    paint.filterQuality = lottieDrawable.filterQuality ?? FilterQuality.low;
    paint.setAlpha(parentAlpha);
    if (_colorFilterAnimation != null) {
      paint.colorFilter = _colorFilterAnimation!.value;
    }
    canvas.save();
    canvas.transform(parentMatrix.storage);
    var src =
        Rect.fromLTWH(0, 0, bitmap.width.toDouble(), bitmap.height.toDouble());
    var dst =
        Rect.fromLTWH(0, 0, bitmap.width.toDouble(), bitmap.height.toDouble());
    canvas.drawImageRect(bitmap, src, dst, paint);
    canvas.restore();
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    var superBounds = super.getBounds(parentMatrix, applyParents: applyParents);
    var bitmap = getBitmap();
    if (bitmap != null) {
      var bounds = Rect.fromLTWH(
          0, 0, bitmap.width.toDouble(), bitmap.height.toDouble());
      return boundsMatrix.mapRect(bounds);
    }
    return superBounds;
  }

  Image? getBitmap() {
    var refId = layerModel.refId;
    return lottieDrawable.getImageAsset(refId);
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
    }
  }
}
