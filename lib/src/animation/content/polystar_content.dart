import 'dart:math';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/polystar_shape.dart';
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
import 'trim_path_content.dart';

class PolystarContent implements PathContent, KeyPathElementContent {
  /// This was empirically derived by creating polystars, converting them to
  /// curves, and calculating a scale factor.
  /// It works best for polygons and stars with 3 points and needs more
  /// work otherwise.
  static const _polystarMagicNumber = .47829;
  static const _polygonMagicNumber = .25;
  final _path = Path();

  final LottieDrawable lottieDrawable;
  final PolystarShape _polystarShape;
  final BaseKeyframeAnimation<Object, double> _pointsAnimation;
  final BaseKeyframeAnimation<Object, Offset> _positionAnimation;
  final BaseKeyframeAnimation<Object, double> _rotationAnimation;
  final BaseKeyframeAnimation<Object, double>? _innerRadiusAnimation;
  final BaseKeyframeAnimation<Object, double> _outerRadiusAnimation;
  final BaseKeyframeAnimation<Object, double>? _innerRoundednessAnimation;
  final BaseKeyframeAnimation<Object, double> _outerRoundednessAnimation;

  final _trimPaths = CompoundTrimPathContent();
  bool _isPathValid = false;

  PolystarContent(this.lottieDrawable, BaseLayer layer, this._polystarShape)
      : _pointsAnimation = _polystarShape.points.createAnimation(),
        _positionAnimation = _polystarShape.position.createAnimation(),
        _rotationAnimation = _polystarShape.rotation.createAnimation(),
        _outerRadiusAnimation = _polystarShape.outerRadius.createAnimation(),
        _outerRoundednessAnimation =
            _polystarShape.outerRoundedness.createAnimation(),
        _innerRadiusAnimation = _polystarShape.type == PolystarShapeType.star
            ? _polystarShape.innerRadius!.createAnimation()
            : null,
        _innerRoundednessAnimation =
            _polystarShape.type == PolystarShapeType.star
                ? _polystarShape.innerRoundedness!.createAnimation()
                : null {
    layer.addAnimation(_pointsAnimation);
    layer.addAnimation(_positionAnimation);
    layer.addAnimation(_rotationAnimation);
    layer.addAnimation(_outerRadiusAnimation);
    layer.addAnimation(_outerRoundednessAnimation);
    if (_polystarShape.type == PolystarShapeType.star) {
      layer.addAnimation(_innerRadiusAnimation);
      layer.addAnimation(_innerRoundednessAnimation);
    }

    _pointsAnimation.addUpdateListener(invalidate);
    _positionAnimation.addUpdateListener(invalidate);
    _rotationAnimation.addUpdateListener(invalidate);
    _outerRadiusAnimation.addUpdateListener(invalidate);
    _outerRoundednessAnimation.addUpdateListener(invalidate);
    if (_polystarShape.type == PolystarShapeType.star) {
      _innerRadiusAnimation!.addUpdateListener(invalidate);
      _innerRoundednessAnimation!.addUpdateListener(invalidate);
    }
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
      }
    }
  }

  @override
  Path getPath() {
    if (_isPathValid) {
      return _path;
    }

    _path.reset();

    if (_polystarShape.hidden) {
      _isPathValid = true;
      return _path;
    }

    switch (_polystarShape.type) {
      case PolystarShapeType.star:
        _createStarPath();
      case PolystarShapeType.polygon:
        _createPolygonPath();
    }

    _path.close();

    _trimPaths.apply(_path);

    _isPathValid = true;
    return _path;
  }

  @override
  String? get name => _polystarShape.name;

  void _createStarPath() {
    var points = _pointsAnimation.value;
    var currentAngle = _rotationAnimation.value;
    // Start at +y instead of +x
    currentAngle -= 90;
    // convert to radians
    currentAngle = radians(currentAngle);
    // adjust current angle for partial points
    var anglePerPoint = 2 * pi / points;
    if (_polystarShape.isReversed) {
      anglePerPoint *= -1;
    }
    var halfAnglePerPoint = anglePerPoint / 2.0;
    var partialPointAmount = points - points.toInt();
    if (partialPointAmount != 0) {
      currentAngle += halfAnglePerPoint * (1.0 - partialPointAmount);
    }

    var outerRadius = _outerRadiusAnimation.value;
    //noinspection ConstantConditions
    var innerRadius = _innerRadiusAnimation!.value;

    var innerRoundedness = 0.0;
    if (_innerRoundednessAnimation != null) {
      innerRoundedness = _innerRoundednessAnimation.value / 100.0;
    }
    var outerRoundedness = _outerRoundednessAnimation.value / 100.0;

    double x;
    double y;
    double previousX;
    double previousY;
    var partialPointRadius = 0.0;
    if (partialPointAmount != 0) {
      partialPointRadius =
          innerRadius + partialPointAmount * (outerRadius - innerRadius);
      x = partialPointRadius * cos(currentAngle);
      y = partialPointRadius * sin(currentAngle);
      _path.moveTo(x, y);
      currentAngle += anglePerPoint * partialPointAmount / 2.0;
    } else {
      x = outerRadius * cos(currentAngle);
      y = outerRadius * sin(currentAngle);
      _path.moveTo(x, y);
      currentAngle += halfAnglePerPoint;
    }

    // True means the line will go to outer radius. False means inner radius.
    var longSegment = false;
    var numPoints = (points.ceil() * 2).toDouble();
    for (var i = 0; i < numPoints; i++) {
      var radius = longSegment ? outerRadius : innerRadius;
      var dTheta = halfAnglePerPoint;
      if (partialPointRadius != 0 && i == numPoints - 2) {
        dTheta = anglePerPoint * partialPointAmount / 2.0;
      }
      if (partialPointRadius != 0 && i == numPoints - 1) {
        radius = partialPointRadius;
      }
      previousX = x;
      previousY = y;
      x = radius * cos(currentAngle);
      y = radius * sin(currentAngle);

      if (innerRoundedness == 0 && outerRoundedness == 0) {
        _path.lineTo(x, y);
      } else {
        var cp1Theta = atan2(previousY, previousX) - pi / 2.0;
        var cp1Dx = cos(cp1Theta);
        var cp1Dy = sin(cp1Theta);

        var cp2Theta = atan2(y, x) - pi / 2.0;
        var cp2Dx = cos(cp2Theta);
        var cp2Dy = sin(cp2Theta);

        var cp1Roundedness = longSegment ? innerRoundedness : outerRoundedness;
        var cp2Roundedness = longSegment ? outerRoundedness : innerRoundedness;
        var cp1Radius = longSegment ? innerRadius : outerRadius;
        var cp2Radius = longSegment ? outerRadius : innerRadius;

        var cp1x = cp1Radius * cp1Roundedness * _polystarMagicNumber * cp1Dx;
        var cp1y = cp1Radius * cp1Roundedness * _polystarMagicNumber * cp1Dy;
        var cp2x = cp2Radius * cp2Roundedness * _polystarMagicNumber * cp2Dx;
        var cp2y = cp2Radius * cp2Roundedness * _polystarMagicNumber * cp2Dy;
        if (partialPointAmount != 0) {
          if (i == 0) {
            cp1x *= partialPointAmount;
            cp1y *= partialPointAmount;
          } else if (i == numPoints - 1) {
            cp2x *= partialPointAmount;
            cp2y *= partialPointAmount;
          }
        }

        _path.cubicTo(
            previousX - cp1x, previousY - cp1y, x + cp2x, y + cp2y, x, y);
      }

      currentAngle += dTheta;
      longSegment = !longSegment;
    }

    var position = _positionAnimation.value;
    _path.shift(position);
    _path.close();
  }

  void _createPolygonPath() {
    var points = _pointsAnimation.value.floor();
    var currentAngle = _rotationAnimation.value;
    // Start at +y instead of +x
    currentAngle -= 90;
    // convert to radians
    currentAngle = radians(currentAngle);
    // adjust current angle for partial points
    var anglePerPoint = 2 * pi / points;

    var roundedness = _outerRoundednessAnimation.value / 100.0;
    var radius = _outerRadiusAnimation.value;
    double x;
    double y;
    double previousX;
    double previousY;
    x = radius * cos(currentAngle);
    y = radius * sin(currentAngle);
    _path.moveTo(x, y);
    currentAngle += anglePerPoint;

    var numPoints = points.toDouble();
    for (var i = 0; i < numPoints; i++) {
      previousX = x;
      previousY = y;
      x = radius * cos(currentAngle);
      y = radius * sin(currentAngle);

      if (roundedness != 0) {
        var cp1Theta = atan2(previousY, previousX) - pi / 2.0;
        var cp1Dx = cos(cp1Theta);
        var cp1Dy = sin(cp1Theta);

        var cp2Theta = atan2(y, x) - pi / 2.0;
        var cp2Dx = cos(cp2Theta);
        var cp2Dy = sin(cp2Theta);

        var cp1x = radius * roundedness * _polygonMagicNumber * cp1Dx;
        var cp1y = radius * roundedness * _polygonMagicNumber * cp1Dy;
        var cp2x = radius * roundedness * _polygonMagicNumber * cp2Dx;
        var cp2y = radius * roundedness * _polygonMagicNumber * cp2Dy;
        _path.cubicTo(
            previousX - cp1x, previousY - cp1y, x + cp2x, y + cp2y, x, y);
      } else {
        _path.lineTo(x, y);
      }

      currentAngle += anglePerPoint;
    }

    var position = _positionAnimation.value;
    _path.shift(position);
    _path.close();
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    MiscUtils.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath, this);
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    if (property == LottieProperty.polystarPoints) {
      _pointsAnimation
          .setValueCallback(callback as LottieValueCallback<double>?);
    } else if (property == LottieProperty.polystarRotation) {
      _rotationAnimation
          .setValueCallback(callback as LottieValueCallback<double>?);
    } else if (property == LottieProperty.position) {
      _positionAnimation
          .setValueCallback(callback as LottieValueCallback<Offset>?);
    } else if (property == LottieProperty.polystarInnerRadius &&
        _innerRadiusAnimation != null) {
      _innerRadiusAnimation
          .setValueCallback(callback as LottieValueCallback<double>?);
    } else if (property == LottieProperty.polystarOuterRadius) {
      _outerRadiusAnimation
          .setValueCallback(callback as LottieValueCallback<double>?);
    } else if (property == LottieProperty.polystarInnerRoundedness &&
        _innerRoundednessAnimation != null) {
      _innerRoundednessAnimation
          .setValueCallback(callback as LottieValueCallback<double>?);
    } else if (property == LottieProperty.polystarOuterRoundedness) {
      _outerRoundednessAnimation
          .setValueCallback(callback as LottieValueCallback<double>?);
    }
  }
}
