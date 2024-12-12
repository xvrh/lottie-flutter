import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/shape_stroke.dart';
import '../../model/layer/base_layer.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/base_keyframe_animation.dart';
import '../keyframe/value_callback_keyframe_animation.dart';
import 'base_stroke_content.dart';

class StrokeContent extends BaseStrokeContent {
  @override
  final String? name;
  final bool _hidden;
  final BaseKeyframeAnimation<Color, Color> _colorAnimation;
  BaseKeyframeAnimation<ColorFilter, ColorFilter?>? _colorFilterAnimation;

  StrokeContent(
      LottieDrawable lottieDrawable, BaseLayer layer, ShapeStroke stroke)
      : name = stroke.name,
        _hidden = stroke.hidden,
        _colorAnimation = stroke.color.createAnimation(),
        super(lottieDrawable, layer,
            cap: lineCapTypeToPaintCap(stroke.capType),
            join: lineJoinTypeToPaintJoin(stroke.joinType),
            miterLimit: stroke.miterLimit,
            opacity: stroke.opacity,
            width: stroke.width,
            dashPattern: stroke.lineDashPattern,
            dashOffset: stroke.dashOffset) {
    _colorAnimation.addUpdateListener(onUpdateListener);
    layer.addAnimation(_colorAnimation);
  }

  @override
  void draw(Canvas canvas, Matrix4 parentMatrix, {required int parentAlpha}) {
    if (_hidden) {
      return;
    }
    paint.color =
        _colorAnimation.value.withAlpha((paint.color.a * 255).toInt());
    if (_colorFilterAnimation != null) {
      paint.colorFilter = _colorFilterAnimation!.value;
    }
    super.draw(canvas, parentMatrix, parentAlpha: parentAlpha);
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    super.addValueCallback(property, callback);
    if (property == LottieProperty.strokeColor) {
      _colorAnimation.setValueCallback(callback as LottieValueCallback<Color>?);
    } else if (property == LottieProperty.colorFilter) {
      if (_colorFilterAnimation != null) {
        layer.removeAnimation(_colorFilterAnimation);
      }

      if (callback == null) {
        _colorFilterAnimation = null;
      } else {
        _colorFilterAnimation = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<ColorFilter>, null)
          ..addUpdateListener(onUpdateListener);
        layer.addAnimation(_colorAnimation);
      }
    }
  }
}
