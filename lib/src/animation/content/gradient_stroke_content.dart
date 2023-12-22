import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/gradient_color.dart';
import '../../model/content/gradient_stroke.dart';
import '../../model/content/gradient_type.dart';
import '../../model/content/shape_stroke.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/base_keyframe_animation.dart';
import '../keyframe/value_callback_keyframe_animation.dart';
import 'base_stroke_content.dart';

class GradientStrokeContent extends BaseStrokeContent {
  /// Cache the gradients such that it runs at 30fps.
  static const _cacheStepsMs = 32;

  @override
  final String? name;
  final bool _hidden;
  final _linearGradientCache = <int, Gradient>{};
  final _radialGradientCache = <int, Gradient>{};

  final GradientType _type;
  final int _cacheSteps;
  final BaseKeyframeAnimation<GradientColor, GradientColor> _colorAnimation;
  final BaseKeyframeAnimation<Offset, Offset> _startPointAnimation;
  final BaseKeyframeAnimation<Offset, Offset> _endPointAnimation;
  ValueCallbackKeyframeAnimation<List<Color>, List<Color>>?
      _colorCallbackAnimation;

  GradientStrokeContent(
      LottieDrawable lottieDrawable, BaseLayer layer, GradientStroke stroke)
      : name = stroke.name,
        _type = stroke.gradientType,
        _hidden = stroke.hidden,
        _cacheSteps =
            (lottieDrawable.composition.duration.inMilliseconds / _cacheStepsMs)
                .round(),
        _colorAnimation = stroke.gradientColor.createAnimation(),
        _startPointAnimation = stroke.startPoint.createAnimation(),
        _endPointAnimation = stroke.endPoint.createAnimation(),
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

    _startPointAnimation.addUpdateListener(onUpdateListener);
    layer.addAnimation(_startPointAnimation);

    _endPointAnimation.addUpdateListener(onUpdateListener);
    layer.addAnimation(_endPointAnimation);
  }

  @override
  void draw(Canvas canvas, Matrix4 parentMatrix, {required int parentAlpha}) {
    if (_hidden) {
      return;
    }

    Gradient gradient;
    if (_type == GradientType.linear) {
      gradient = _getLinearGradient(parentMatrix);
    } else {
      gradient = _getRadialGradient(parentMatrix);
    }

    paint.shader = gradient;

    super.draw(canvas, parentMatrix, parentAlpha: parentAlpha);
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
    if (gradientHash != null) {
      _linearGradientCache[gradientHash] = gradient;
    }
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
    gradient = Gradient.radial(startPoint, radius, colors, positions,
        TileMode.clamp, parentMatrix.storage);
    if (gradientHash != null) {
      _radialGradientCache[gradientHash] = gradient;
    }
    return gradient;
  }

  //TODO(xha): cache the shader based on the input parameters and not the animation
  // progress.
  // At first, log when there is too many cache miss.
  int? _getGradientHash(Matrix4 parentMatrix) {
    // Don't cache gradient if ValueDelegate.gradient is used
    if (_colorCallbackAnimation != null) return null;

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
      var dynamicColors = _colorCallbackAnimation!.value;
      if (colors.length == dynamicColors.length) {
        for (var i = 0; i < colors.length; i++) {
          colors[i] = dynamicColors[i];
        }
      } else {
        colors =
            List<Color>.filled(dynamicColors.length, const Color(0x00000000));
        for (var i = 0; i < dynamicColors.length; i++) {
          colors[i] = dynamicColors[i];
        }
      }
    }
    return colors;
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    super.addValueCallback(property, callback);
    if (property == LottieProperty.gradientColor) {
      if (_colorCallbackAnimation != null) {
        layer.removeAnimation(_colorCallbackAnimation);
      }

      if (callback == null) {
        _colorCallbackAnimation = null;
      } else {
        _colorCallbackAnimation = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<List<Color>>, <Color>[])
          ..addUpdateListener(onUpdateListener);
        layer.addAnimation(_colorCallbackAnimation);
      }
    }
  }
}
