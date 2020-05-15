import 'dart:math';
import 'dart:ui';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../l.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/animatable/animatable_double_value.dart';
import '../../model/animatable/animatable_integer_value.dart';
import '../../model/content/shape_trim_path.dart';
import '../../model/key_path.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../utils/dash_path.dart';
import '../../utils/misc.dart';
import '../../utils/utils.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/base_keyframe_animation.dart';
import '../keyframe/value_callback_keyframe_animation.dart';
import 'content.dart';
import 'drawing_content.dart';
import 'key_path_element_content.dart';
import 'path_content.dart';
import 'trim_path_content.dart';

abstract class BaseStrokeContent
    implements KeyPathElementContent, DrawingContent {
  final Path _path = Path();
  final Path _trimPathPath = Path();
  final LottieDrawable lottieDrawable;
  final BaseLayer layer;
  final List<_PathGroup> _pathGroups = <_PathGroup>[];
  final List<double> _dashPatternValues;
  final Paint paint = Paint()..style = PaintingStyle.stroke;

  final BaseKeyframeAnimation<dynamic, double> _widthAnimation;
  final BaseKeyframeAnimation<dynamic, int> _opacityAnimation;
  final List<BaseKeyframeAnimation<dynamic, double>> _dashPatternAnimations;
  final BaseKeyframeAnimation<dynamic,
      double> /*?*/ _dashPatternOffsetAnimation;
  BaseKeyframeAnimation<ColorFilter, ColorFilter> /*?*/ _colorFilterAnimation;

  BaseStrokeContent(this.lottieDrawable, this.layer,
      {StrokeCap cap,
      StrokeJoin join,
      double miterLimit,
      AnimatableIntegerValue opacity,
      AnimatableDoubleValue width,
      List<AnimatableDoubleValue> dashPattern,
      AnimatableDoubleValue dashOffset})
      : _widthAnimation = width.createAnimation(),
        _opacityAnimation = opacity.createAnimation(),
        _dashPatternOffsetAnimation = dashOffset?.createAnimation(),
        _dashPatternAnimations =
            dashPattern.map((d) => d.createAnimation()).toList(),
        _dashPatternValues = List.filled(dashPattern.length, 0.0) {
    paint
      ..strokeCap = cap
      ..strokeJoin = join
      ..strokeMiterLimit = miterLimit;

    layer.addAnimation(_opacityAnimation);
    layer.addAnimation(_widthAnimation);
    for (var i = 0; i < _dashPatternAnimations.length; i++) {
      layer.addAnimation(_dashPatternAnimations[i]);
    }
    if (_dashPatternOffsetAnimation != null) {
      layer.addAnimation(_dashPatternOffsetAnimation);
    }

    _opacityAnimation.addUpdateListener(onUpdateListener);
    _widthAnimation.addUpdateListener(onUpdateListener);

    for (var i = 0; i < dashPattern.length; i++) {
      _dashPatternAnimations[i].addUpdateListener(onUpdateListener);
    }
    if (_dashPatternOffsetAnimation != null) {
      _dashPatternOffsetAnimation.addUpdateListener(onUpdateListener);
    }
  }

  void onUpdateListener() {
    lottieDrawable.invalidateSelf();
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    TrimPathContent trimPathContentBefore;
    for (var i = contentsBefore.length - 1; i >= 0; i--) {
      var content = contentsBefore[i];
      if (content is TrimPathContent &&
          content.type == ShapeTrimPathType.individually) {
        trimPathContentBefore = content;
      }
    }
    if (trimPathContentBefore != null) {
      trimPathContentBefore.addListener(onUpdateListener);
    }

    _PathGroup currentPathGroup;
    for (var i = contentsAfter.length - 1; i >= 0; i--) {
      var content = contentsAfter[i];
      if (content is TrimPathContent &&
          content.type == ShapeTrimPathType.individually) {
        if (currentPathGroup != null) {
          _pathGroups.add(currentPathGroup);
        }
        currentPathGroup = _PathGroup(content);
        content.addListener(onUpdateListener);
      } else if (content is PathContent) {
        currentPathGroup ??= _PathGroup(trimPathContentBefore);
        currentPathGroup.paths.add(content);
      }
    }
    if (currentPathGroup != null) {
      _pathGroups.add(currentPathGroup);
    }
  }

  @override
  void draw(Canvas canvas, Size size, Matrix4 parentMatrix, {int parentAlpha}) {
    L.beginSection('StrokeContent#draw');
    if (parentMatrix.hasZeroScaleAxis) {
      L.endSection('StrokeContent#draw');
      return;
    }
    var alpha =
        ((parentAlpha / 255.0 * _opacityAnimation.value / 100.0) * 255).round();
    paint.setAlpha(alpha.clamp(0, 255).toInt());
    paint.strokeWidth = _widthAnimation.value * parentMatrix.getScale();
    if (paint.strokeWidth <= 0) {
      // Android draws a hairline stroke for 0, After Effects doesn't.
      L.endSection('StrokeContent#draw');
      return;
    }

    if (_colorFilterAnimation != null) {
      paint.colorFilter = _colorFilterAnimation.value;
    }

    for (var i = 0; i < _pathGroups.length; i++) {
      var pathGroup = _pathGroups[i];

      if (pathGroup.trimPath != null) {
        _applyTrimPath(canvas, pathGroup, parentMatrix);
      } else {
        L.beginSection('StrokeContent#buildPath');
        _path.reset();
        for (var j = pathGroup.paths.length - 1; j >= 0; j--) {
          _path.addPath(pathGroup.paths[j].getPath(), Offset.zero,
              matrix4: parentMatrix.storage);
        }
        L.endSection('StrokeContent#buildPath');
        L.beginSection('StrokeContent#drawPath');
        canvas.drawPath(_withDashPattern(_path, parentMatrix), paint);
        L.endSection('StrokeContent#drawPath');
      }
    }
    L.endSection('StrokeContent#draw');
  }

  void _applyTrimPath(
      Canvas canvas, _PathGroup pathGroup, Matrix4 parentMatrix) {
    L.beginSection('StrokeContent#applyTrimPath');
    if (pathGroup.trimPath == null) {
      L.endSection('StrokeContent#applyTrimPath');
      return;
    }
    _path.reset();
    for (var j = pathGroup.paths.length - 1; j >= 0; j--) {
      _path.addPath(pathGroup.paths[j].getPath(), Offset.zero,
          matrix4: parentMatrix.storage);
    }
    var pathMetrics = _path.computeMetrics().toList();
    var totalLength = pathMetrics.fold<double>(0.0, (a, b) => a + b.length);

    var offsetLength = totalLength * pathGroup.trimPath.offset.value / 360.0;
    var startLength =
        totalLength * pathGroup.trimPath.start.value / 100.0 + offsetLength;
    var endLength =
        totalLength * pathGroup.trimPath.end.value / 100.0 + offsetLength;

    var currentLength = 0.0;
    for (var j = pathGroup.paths.length - 1; j >= 0; j--) {
      _trimPathPath
          .set(pathGroup.paths[j].getPath().transform(parentMatrix.storage));
      var pathMetrics = _trimPathPath.computeMetrics().toList();
      var length = pathMetrics.first.length;
      if (endLength > totalLength &&
          endLength - totalLength < currentLength + length &&
          currentLength < endLength - totalLength) {
        // Draw the segment when the end is greater than the length which wraps around to the
        // beginning.
        double startValue;
        if (startLength > totalLength) {
          startValue = (startLength - totalLength) / length;
        } else {
          startValue = 0;
        }
        var endValue = min((endLength - totalLength) / length, 1).toDouble();
        Utils.applyTrimPathIfNeeded(_trimPathPath, startValue, endValue, 0.0);
        canvas.drawPath(_withDashPattern(_trimPathPath, parentMatrix), paint);
      } else if (currentLength + length < startLength ||
          currentLength > endLength) {
        // Do nothing
      } else if (currentLength + length <= endLength &&
          startLength < currentLength) {
        canvas.drawPath(_withDashPattern(_trimPathPath, parentMatrix), paint);
      } else {
        double startValue;
        if (startLength < currentLength) {
          startValue = 0;
        } else {
          startValue = (startLength - currentLength) / length;
        }
        double endValue;
        if (endLength > currentLength + length) {
          endValue = 1.0;
        } else {
          endValue = (endLength - currentLength) / length;
        }
        Utils.applyTrimPathIfNeeded(_trimPathPath, startValue, endValue, 0);
        canvas.drawPath(_withDashPattern(_trimPathPath, parentMatrix), paint);
      }
      currentLength += length;
    }
    L.endSection('StrokeContent#applyTrimPath');
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {bool applyParents}) {
    L.beginSection('StrokeContent#getBounds');
    _path.reset();
    for (var i = 0; i < _pathGroups.length; i++) {
      var pathGroup = _pathGroups[i];
      for (var j = 0; j < pathGroup.paths.length; j++) {
        _path.addPath(pathGroup.paths[j].getPath(), Offset.zero,
            matrix4: parentMatrix.storage);
      }
    }
    var bounds = _path.getBounds();

    var width = _widthAnimation.value;
    bounds = Rect.fromLTWH(bounds.left - width / 2.0, bounds.top - width / 2.0,
        bounds.right + width / 2.0, bounds.bottom + width / 2.0);
    // Add padding to account for rounding errors.
    bounds = Rect.fromLTWH(
        bounds.left - 1, bounds.top - 1, bounds.right + 1, bounds.bottom + 1);
    L.endSection('StrokeContent#getBounds');
    return bounds;
  }

  Path _withDashPattern(Path path, Matrix4 parentMatrix) {
    L.beginSection('StrokeContent#applyDashPattern');
    if (_dashPatternAnimations.isEmpty) {
      L.endSection('StrokeContent#applyDashPattern');
      return path;
    }

    var scale = parentMatrix.getScale();
    for (var i = 0; i < _dashPatternAnimations.length; i++) {
      _dashPatternValues[i] = _dashPatternAnimations[i].value;
      // If the value of the dash pattern or gap is too small, the number of individual sections
      // approaches infinity as the value approaches 0.
      // To mitigate this, we essentially put a minimum value on the dash pattern size of 1px
      // and a minimum gap size of 0.01.
      if (i % 2 == 0) {
        if (_dashPatternValues[i] < 1.0) {
          _dashPatternValues[i] = 1.0;
        }
      } else {
        if (_dashPatternValues[i] < 0.1) {
          _dashPatternValues[i] = 0.1;
        }
      }
      _dashPatternValues[i] *= scale;
    }

    var offset = _dashPatternOffsetAnimation == null
        ? 0.0
        : _dashPatternOffsetAnimation.value * scale;
    var newPath = dashPath(path, intervals: _dashPatternValues, phase: offset);
    L.endSection('StrokeContent#applyDashPattern');

    return newPath;
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    MiscUtils.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath, this);
  }

  @override
  @mustCallSuper
  void addValueCallback<T>(T property, LottieValueCallback<T> /*?*/ callback) {
    if (property == LottieProperty.opacity) {
      _opacityAnimation.setValueCallback(callback as LottieValueCallback<int>);
    } else if (property == LottieProperty.strokeWidth) {
      _widthAnimation.setValueCallback(callback as LottieValueCallback<double>);
    } else if (property == LottieProperty.colorFilter) {
      if (_colorFilterAnimation != null) {
        layer.removeAnimation(_colorFilterAnimation);
      }

      if (callback == null) {
        _colorFilterAnimation = null;
      } else {
        _colorFilterAnimation =
            ValueCallbackKeyframeAnimation<ColorFilter, ColorFilter>(
                callback as LottieValueCallback<ColorFilter>);
        _colorFilterAnimation.addUpdateListener(onUpdateListener);
        layer.addAnimation(_colorFilterAnimation);
      }
    }
  }
}

/// Data class to help drawing trim paths individually.
class _PathGroup {
  final List<PathContent> paths = <PathContent>[];
  final TrimPathContent /*?*/ trimPath;

  _PathGroup(this.trimPath);
}
