import 'dart:math';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/rectangle_shape.dart';
import '../../model/content/shape_trim_path.dart';
import '../../model/key_path.dart';
import '../../model/layer/base_layer.dart';
import '../../utils/misc.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/base_keyframe_animation.dart';
import 'compound_trim_path_content.dart';
import 'content.dart';
import 'key_path_element_content.dart';
import 'path_content.dart';
import 'rounded_corners_content.dart';
import 'trim_path_content.dart';

class RectangleContent implements KeyPathElementContent, PathContent {
  final _path = Path();

  @override
  final String? name;
  final bool _hidden;
  final LottieDrawable lottieDrawable;
  final BaseKeyframeAnimation<Object, Offset> _positionAnimation;
  final BaseKeyframeAnimation<Object, Offset> _sizeAnimation;
  final BaseKeyframeAnimation<Object, double> _cornerRadiusAnimation;

  final CompoundTrimPathContent _trimPaths = CompoundTrimPathContent();

  /// This corner radius is from a layer item. The first one is from the roundedness on this specific rect.
  BaseKeyframeAnimation<double, double>? _roundedCornersAnimation;
  bool _isPathValid = false;

  RectangleContent(
      this.lottieDrawable, BaseLayer layer, RectangleShape rectShape)
      : name = rectShape.name,
        _hidden = rectShape.hidden,
        _positionAnimation = rectShape.position.createAnimation(),
        _sizeAnimation = rectShape.size.createAnimation(),
        _cornerRadiusAnimation = rectShape.cornerRadius.createAnimation() {
    layer.addAnimation(_positionAnimation);
    layer.addAnimation(_sizeAnimation);
    layer.addAnimation(_cornerRadiusAnimation);

    _positionAnimation.addUpdateListener(invalidate);
    _sizeAnimation.addUpdateListener(invalidate);
    _cornerRadiusAnimation.addUpdateListener(invalidate);
  }

  void invalidate() {
    _isPathValid = false;
    lottieDrawable.invalidateSelf();
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    for (var i = 0; i < contentsBefore.length; i++) {
      var content = contentsBefore[i];
      if (content is TrimPathContent &&
          content.type == ShapeTrimPathType.simultaneously) {
        var trimPath = content;
        _trimPaths.addTrimPath(trimPath);
        trimPath.addListener(invalidate);
      } else if (content is RoundedCornersContent) {
        _roundedCornersAnimation = content.roundedCorners;
      }
    }
  }

  @override
  Path getPath() {
    if (_isPathValid) {
      return _path;
    }

    _path.reset();

    if (_hidden) {
      _isPathValid = true;
      return _path;
    }

    var size = _sizeAnimation.value;
    var halfWidth = size.dx / 2.0;
    var halfHeight = size.dy / 2.0;
    var radius = _cornerRadiusAnimation.value;
    var roundedCornersAnimation = _roundedCornersAnimation;
    if (radius == 0 && roundedCornersAnimation != null) {
      radius = min(roundedCornersAnimation.value, min(halfWidth, halfHeight));
    }
    var maxRadius = min(halfWidth, halfHeight);
    if (radius > maxRadius) {
      radius = maxRadius;
    }

    // Draw the rectangle top right to bottom left.
    var position = _positionAnimation.value;

    _path.moveTo(position.dx + halfWidth, position.dy - halfHeight + radius);

    _path.lineTo(position.dx + halfWidth, position.dy + halfHeight - radius);

    if (radius > 0) {
      _path.arcTo(
          Rect.fromLTRB(
              position.dx + halfWidth - 2 * radius,
              position.dy + halfHeight - 2 * radius,
              position.dx + halfWidth,
              position.dy + halfHeight),
          0,
          radians(90),
          false);
    }

    _path.lineTo(position.dx - halfWidth + radius, position.dy + halfHeight);

    if (radius > 0) {
      _path.arcTo(
          Rect.fromLTRB(
              position.dx - halfWidth,
              position.dy + halfHeight - 2 * radius,
              position.dx - halfWidth + 2 * radius,
              position.dy + halfHeight),
          radians(90),
          radians(90),
          false);
    }

    _path.lineTo(position.dx - halfWidth, position.dy - halfHeight + radius);

    if (radius > 0) {
      _path.arcTo(
          Rect.fromLTRB(
              position.dx - halfWidth,
              position.dy - halfHeight,
              position.dx - halfWidth + 2 * radius,
              position.dy - halfHeight + 2 * radius),
          radians(180),
          radians(90),
          false);
    }

    _path.lineTo(position.dx + halfWidth - radius, position.dy - halfHeight);

    if (radius > 0) {
      _path.arcTo(
          Rect.fromLTRB(
              position.dx + halfWidth - 2 * radius,
              position.dy - halfHeight,
              position.dx + halfWidth,
              position.dy - halfHeight + 2 * radius),
          radians(270),
          radians(90),
          false);
    }
    _path.close();

    _trimPaths.apply(_path);

    _isPathValid = true;
    return _path;
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    MiscUtils.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath, this);
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    if (property == LottieProperty.rectangleSize) {
      _sizeAnimation.setValueCallback(callback as LottieValueCallback<Offset>?);
    } else if (property == LottieProperty.position) {
      _positionAnimation
          .setValueCallback(callback as LottieValueCallback<Offset>?);
    } else if (property == LottieProperty.cornerRadius) {
      _cornerRadiusAnimation
          .setValueCallback(callback as LottieValueCallback<double>?);
    }
  }
}
