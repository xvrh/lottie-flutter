import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../l.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/gradient_color.dart';
import '../../model/content/gradient_fill.dart';
import '../../model/content/gradient_type.dart';
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

class GradientFillContent implements DrawingContent, KeyPathElementContent {
  /// Cache the gradients such that it runs at 30fps.
  static final int _cacheStepsMs = 32;
  final BaseLayer layer;
  final GradientFill _fill;
  final _linearGradientCache = <int, Gradient>{};
  final _radialGradientCache = <int, Gradient>{};
  final _path = Path();
  final _paint = Paint();
  final _paths = <PathContent>[];
  final BaseKeyframeAnimation<GradientColor, GradientColor> _colorAnimation;
  final BaseKeyframeAnimation<int, int> _opacityAnimation;
  final BaseKeyframeAnimation<Offset, Offset> _startPointAnimation;
  final BaseKeyframeAnimation<Offset, Offset> _endPointAnimation;
  BaseKeyframeAnimation<ColorFilter, ColorFilter> /*?*/ _colorFilterAnimation;
  ValueCallbackKeyframeAnimation<List<Color>,
      List<Color>> /*?*/ _colorCallbackAnimation;
  final LottieDrawable lottieDrawable;
  final int _cacheSteps;

  GradientFillContent(this.lottieDrawable, this.layer, this._fill)
      : _cacheSteps =
            (lottieDrawable.composition.duration.inMilliseconds / _cacheStepsMs)
                .round(),
        _colorAnimation = _fill.gradientColor.createAnimation(),
        _opacityAnimation = _fill.opacity.createAnimation(),
        _startPointAnimation = _fill.startPoint.createAnimation(),
        _endPointAnimation = _fill.endPoint.createAnimation() {
    _path.fillType = _fill.fillType;
    _colorAnimation.addUpdateListener(invalidate);
    layer.addAnimation(_colorAnimation);

    _opacityAnimation.addUpdateListener(invalidate);
    layer.addAnimation(_opacityAnimation);

    _startPointAnimation.addUpdateListener(invalidate);
    layer.addAnimation(_startPointAnimation);

    _endPointAnimation.addUpdateListener(invalidate);
    layer.addAnimation(_endPointAnimation);
  }

  @override
  String get name => _fill.name;

  void invalidate() {
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
    if (_fill.hidden) {
      return;
    }
    L.beginSection('GradientFillContent#draw');
    _path.reset();
    for (var i = 0; i < _paths.length; i++) {
      _path.addPath(_paths[i].getPath(), Offset.zero,
          matrix4: parentMatrix.storage);
    }

    Gradient gradient;
    if (_fill.gradientType == GradientType.linear) {
      gradient = _getLinearGradient(parentMatrix);
    } else {
      gradient = _getRadialGradient(parentMatrix);
    }

    _paint.shader = gradient;

    if (_colorFilterAnimation != null) {
      _paint.colorFilter = _colorFilterAnimation.value;
    }

    var alpha =
        ((parentAlpha / 255.0 * _opacityAnimation.value / 100.0) * 255).round();
    _paint.setAlpha(alpha.clamp(0, 255).toInt());

    canvas.drawPath(_path, _paint);
    L.endSection('GradientFillContent#draw');
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
    return Rect.fromLTWH(outBounds.left - 1, outBounds.top - 1,
        outBounds.right + 1, outBounds.bottom + 1);
  }

  Gradient _getLinearGradient(Matrix4 parentMatrix) {
    var gradientHash = _getGradientHash(parentMatrix);
    var gradient = _linearGradientCache[gradientHash];
    if (gradient != null) {
      return gradient;
    }
    var startPoint = _startPointAnimation.value;
    var endPoint = _endPointAnimation.value;
    var gradientColor = _colorAnimation.value;
    var colors = _applyDynamicColorsIfNeeded(gradientColor.colors);
    var positions = gradientColor.positions;
    gradient = Gradient.linear(startPoint, endPoint, colors, positions,
        TileMode.clamp, parentMatrix.storage);
    _linearGradientCache[gradientHash] = gradient;
    return gradient;
  }

  Gradient _getRadialGradient(Matrix4 parentMatrix) {
    var gradientHash = _getGradientHash(parentMatrix);
    var gradient = _radialGradientCache[gradientHash];
    if (gradient != null) {
      return gradient;
    }
    var startPoint = _startPointAnimation.value;
    var endPoint = _endPointAnimation.value;
    var gradientColor = _colorAnimation.value;
    var colors = _applyDynamicColorsIfNeeded(gradientColor.colors);
    var positions = gradientColor.positions;
    var x0 = startPoint.dx;
    var y0 = startPoint.dy;
    var x1 = endPoint.dx;
    var y1 = endPoint.dy;
    var radius = hypot(x1 - x0, y1 - y0).toDouble();
    if (radius <= 0) {
      radius = 0.001;
    }
    gradient = Gradient.radial(startPoint, radius, colors, positions,
        TileMode.clamp, parentMatrix.storage);
    _radialGradientCache[gradientHash] = gradient;
    return gradient;
  }

  int _getGradientHash(Matrix4 parentMatrix) {
    var startPointProgress =
        (_startPointAnimation.progress * _cacheSteps).round();
    var endPointProgress = (_endPointAnimation.progress * _cacheSteps).round();
    var colorProgress = (_colorAnimation.progress * _cacheSteps).round();
    var hash = 17;
    if (startPointProgress != 0) {
      hash = hash * 31 * startPointProgress;
    }
    if (endPointProgress != 0) {
      hash = hash * 31 * endPointProgress;
    }
    if (colorProgress != 0) {
      hash = hash * 31 * colorProgress;
    }
    hash *= 31 * parentMatrix.hashCode;
    return hash;
  }

  List<Color> _applyDynamicColorsIfNeeded(List<Color> colors) {
    if (_colorCallbackAnimation != null) {
      var dynamicColors = _colorCallbackAnimation.value;
      if (colors.length == dynamicColors.length) {
        for (var i = 0; i < colors.length; i++) {
          colors[i] = dynamicColors[i];
        }
      } else {
        colors = List.filled(dynamicColors.length, Color(0));
        for (var i = 0; i < dynamicColors.length; i++) {
          colors[i] = dynamicColors[i];
        }
      }
    }
    return colors;
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    MiscUtils.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath, this);
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T> /*?*/ callback) {
    if (property == LottieProperty.opacity) {
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
        _colorFilterAnimation.addUpdateListener(invalidate);
        layer.addAnimation(_colorFilterAnimation);
      }
    } else if (property == LottieProperty.gradientColor) {
      if (_colorCallbackAnimation != null) {
        layer.removeAnimation(_colorCallbackAnimation);
      }

      if (callback == null) {
        _colorCallbackAnimation = null;
      } else {
        _colorCallbackAnimation = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<List<Color>>);
        _colorCallbackAnimation.addUpdateListener(invalidate);
        layer.addAnimation(_colorCallbackAnimation);
      }
    }
  }
}
