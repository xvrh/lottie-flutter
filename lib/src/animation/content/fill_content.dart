import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../l.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/shape_fill.dart';
import '../../model/key_path.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../utils/misc.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/base_keyframe_animation.dart';
import '../keyframe/value_callback_keyframe_animation.dart';
import 'content.dart';
import 'drawing_content.dart';
import 'key_path_element_content.dart';
import 'path_content.dart';

class FillContent implements DrawingContent, KeyPathElementContent {
  final Path _path = Path();
  final Paint _paint = Paint();
  final BaseLayer layer;
  @override
  final String name;
  final bool _hidden;
  final List<PathContent> _paths = <PathContent>[];
  BaseKeyframeAnimation<Color, Color> _colorAnimation;
  BaseKeyframeAnimation<int, int> _opacityAnimation;
  BaseKeyframeAnimation<ColorFilter, ColorFilter> /*?*/ _colorFilterAnimation;
  final LottieDrawable lottieDrawable;

  FillContent(this.lottieDrawable, this.layer, ShapeFill fill)
      : name = fill.name,
        _hidden = fill.hidden {
    if (fill.color == null || fill.opacity == null) {
      return;
    }

    _path.fillType = fill.fillType;

    _colorAnimation = fill.color.createAnimation();
    _colorAnimation.addUpdateListener(onValueChanged);
    layer.addAnimation(_colorAnimation);
    _opacityAnimation = fill.opacity.createAnimation();
    _opacityAnimation.addUpdateListener(onValueChanged);
    layer.addAnimation(_opacityAnimation);
  }

  void onValueChanged() {
    lottieDrawable.invalidateSelf();
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    for (var i = 0; i < contentsAfter.length; i++) {
      var content = contentsAfter[i];
      if (content is PathContent) {
        _paths.add(content);
      }
    }
  }

  @override
  void draw(Canvas canvas, Size size, Matrix4 parentMatrix, {int parentAlpha}) {
    if (_hidden) {
      return;
    }
    L.beginSection('FillContent#draw');
    _paint.color = _colorAnimation.value;
    var alpha =
        ((parentAlpha / 255.0 * _opacityAnimation.value / 100.0) * 255).round();
    _paint.setAlpha(alpha.clamp(0, 255).toInt());

    if (_colorFilterAnimation != null) {
      _paint.colorFilter = _colorFilterAnimation.value;
    }

    _path.reset();
    for (var i = 0; i < _paths.length; i++) {
      _path.addPath(_paths[i].getPath(), Offset.zero,
          matrix4: parentMatrix.storage);
    }

    canvas.drawPath(_path, _paint);

    L.endSection('FillContent#draw');
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {bool applyParents}) {
    _path.reset();
    for (var i = 0; i < _paths.length; i++) {
      _path.addPath(_paths[i].getPath(), Offset.zero,
          matrix4: parentMatrix.storage);
    }
    var outBounds = _path.getBounds();
    // Add padding to account for rounding errors.
    outBounds = Rect.fromLTWH(outBounds.left - 1, outBounds.top - 1,
        outBounds.right + 1, outBounds.bottom + 1);
    return outBounds;
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    MiscUtils.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath, this);
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T> /*?*/ callback) {
    if (property == LottieProperty.color) {
      _colorAnimation.setValueCallback(callback as LottieValueCallback<Color>);
    } else if (property == LottieProperty.opacity) {
      _opacityAnimation.setValueCallback(callback as LottieValueCallback<int>);
    } else if (property == LottieProperty.colorFilter) {
      if (_colorFilterAnimation != null) {
        layer.removeAnimation(_colorFilterAnimation);
      }

      if (callback == null) {
        _colorFilterAnimation = null;
      } else {
        _colorFilterAnimation = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<ColorFilter>);
        _colorFilterAnimation.addUpdateListener(onValueChanged);
        layer.addAnimation(_colorFilterAnimation);
      }
    }
  }
}
