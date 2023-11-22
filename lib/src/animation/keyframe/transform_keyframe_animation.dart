import 'dart:math' hide Point, Rectangle;
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../lottie_property.dart';
import '../../model/animatable/animatable_transform.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../value/keyframe.dart';
import '../../value/lottie_value_callback.dart';
import 'base_keyframe_animation.dart';
import 'double_keyframe_animation.dart';
import 'value_callback_keyframe_animation.dart';

class TransformKeyframeAnimation {
  TransformKeyframeAnimation(AnimatableTransform animatableTransform)
      : _skewMatrix1 =
            animatableTransform.skew == null ? null : Matrix4.identity(),
        _skewMatrix2 =
            animatableTransform.skew == null ? null : Matrix4.identity(),
        _skewMatrix3 =
            animatableTransform.skew == null ? null : Matrix4.identity(),
        _anchorPoint = animatableTransform.anchorPoint?.createAnimation(),
        _position = animatableTransform.position?.createAnimation(),
        _scale = animatableTransform.scale?.createAnimation(),
        _rotation = animatableTransform.rotation?.createAnimation(),
        _autoOrient = animatableTransform.isAutoOrient,
        _skew = animatableTransform.skew?.createAnimation(),
        _skewAngle = animatableTransform.skewAngle?.createAnimation(),
        _opacity = animatableTransform.opacity?.createAnimation(),
        _startOpacity = animatableTransform.startOpacity?.createAnimation(),
        _endOpacity = animatableTransform.endOpacity?.createAnimation();

  final _matrix = Matrix4.identity();
  final Matrix4? _skewMatrix1;
  final Matrix4? _skewMatrix2;
  final Matrix4? _skewMatrix3;

  BaseKeyframeAnimation<Offset, Offset>? _anchorPoint;
  BaseKeyframeAnimation<Offset, Offset>? _position;
  BaseKeyframeAnimation<Offset, Offset>? _scale;
  BaseKeyframeAnimation<double, double>? _rotation;
  DoubleKeyframeAnimation? _skew;
  DoubleKeyframeAnimation? _skewAngle;

  BaseKeyframeAnimation<int, int>? _opacity;
  BaseKeyframeAnimation<int, int>? get opacity => _opacity;

  BaseKeyframeAnimation<double, double>? _startOpacity;
  BaseKeyframeAnimation<double, double>? get startOpacity => _startOpacity;

  BaseKeyframeAnimation<double, double>? _endOpacity;
  BaseKeyframeAnimation<double, double>? get endOpacity => _endOpacity;

  final bool _autoOrient;

  void addAnimationsToLayer(BaseLayer layer) {
    layer.addAnimation(_opacity);
    layer.addAnimation(_startOpacity);
    layer.addAnimation(_endOpacity);

    layer.addAnimation(_anchorPoint);
    layer.addAnimation(_position);
    layer.addAnimation(_scale);
    layer.addAnimation(_rotation);
    layer.addAnimation(_skew);
    layer.addAnimation(_skewAngle);
  }

  void addListener(void Function() listener) {
    _opacity?.addUpdateListener(listener);
    _startOpacity?.addUpdateListener(listener);
    _endOpacity?.addUpdateListener(listener);
    _anchorPoint?.addUpdateListener(listener);
    _position?.addUpdateListener(listener);
    _scale?.addUpdateListener(listener);
    _rotation?.addUpdateListener(listener);
    _skew?.addUpdateListener(listener);
    _skewAngle?.addUpdateListener(listener);
  }

  void setProgress(double progress) {
    _opacity?.setProgress(progress);
    _startOpacity?.setProgress(progress);
    _endOpacity?.setProgress(progress);
    _anchorPoint?.setProgress(progress);
    _position?.setProgress(progress);
    _scale?.setProgress(progress);
    _rotation?.setProgress(progress);
    _skew?.setProgress(progress);
    _skewAngle?.setProgress(progress);
  }

  Matrix4 getMatrix() {
    _matrix.reset();

    if (_position != null) {
      final position = _position!.value;
      if (position.dx != 0 || position.dy != 0) {
        _matrix.translate(position.dx, position.dy);
      }
    }

    // If autoOrient is true, the rotation should follow the derivative of the position rather
    // than the rotation property.
    if (_autoOrient) {
      if (_position case var position?) {
        var currentProgress = position.progress;
        var startPosition = position.value;
        // Store the start X and Y values because the pointF will be overwritten by the next getValue call.
        var startX = startPosition.dx;
        var startY = startPosition.dy;
        // 1) Find the next position value.
        // 2) Create a vector from the current position to the next position.
        // 3) Find the angle of that vector to the X axis (0 degrees).
        position.setProgress(currentProgress + 0.0001);
        var nextPosition = position.value;
        position.setProgress(currentProgress);
        var rotationValue =
            degrees(atan2(nextPosition.dy - startY, nextPosition.dx - startX));
        _matrix.rotateZ(rotationValue);
      }
    } else {
      if (_rotation != null) {
        final rotation = _rotation!.value;
        if (rotation != 0) {
          _matrix.rotateZ(rotation * pi / 180.0);
        }
      }
    }

    if (_skew != null) {
      final mCos =
          _skewAngle == null ? 0.0 : cos(radians(-_skewAngle!.value + 90));
      final mSin =
          _skewAngle == null ? 1.0 : sin(radians(-_skewAngle!.value + 90));
      final aTan = tan(radians(_skew!.value));

      _skewMatrix1!.setValues(
        mCos, mSin, 0, 0,
        -mSin, mCos, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1, //
      );

      _skewMatrix2!.setValues(
        1, 0, 0, 0,
        aTan, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1, //
      );

      _skewMatrix3!.setValues(
        mCos, -mSin, 0, 0,
        mSin, mCos, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1, //
      );

      _skewMatrix2.multiply(_skewMatrix1);
      _skewMatrix3.multiply(_skewMatrix2);
      _matrix.multiply(_skewMatrix3);
    }

    if (_scale != null) {
      final scale = _scale!.value;
      if (scale.dx != 1 || scale.dy != 1) {
        _matrix.scale(scale.dx, scale.dy);
      }
    }

    if (_anchorPoint != null) {
      final anchorPoint = _anchorPoint!.value;
      if (anchorPoint.dx != 0 || anchorPoint.dy != 0) {
        _matrix.translate(-anchorPoint.dx, -anchorPoint.dy);
      }
    }

    return _matrix;
  }

  /// TODO: see if we can use this for the main {@link #getMatrix()} method.
  Matrix4 getMatrixForRepeater(double amount) {
    final position = _position?.value;
    final scale = _scale?.value;

    _matrix.setIdentity();

    if (position != null) {
      _matrix.translate(position.dx * amount, position.dy * amount);
    }

    if (scale != null) {
      _matrix.scale(
          pow(scale.dx, amount).toDouble(), pow(scale.dy, amount).toDouble());
    }

    if (_rotation != null) {
      var rotation = _rotation!.value;
      var anchorPoint = _anchorPoint?.value;
      _matrix.rotate(
          Vector3(anchorPoint == null ? 0.0 : anchorPoint.dx,
              anchorPoint == null ? 0.0 : anchorPoint.dy, 1.0),
          radians(rotation * amount));
    }

    return _matrix;
  }

  bool applyValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    if (property == LottieProperty.transformAnchorPoint) {
      if (_anchorPoint == null) {
        _anchorPoint = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<Offset>?, Offset.zero);
      } else {
        _anchorPoint!
            .setValueCallback(callback as LottieValueCallback<Offset>?);
      }
    } else if (property == LottieProperty.transformPosition) {
      if (_position == null) {
        _position = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<Offset>?, Offset.zero);
      } else {
        _position!.setValueCallback(callback as LottieValueCallback<Offset>?);
      }
    } else if (property == LottieProperty.transformScale) {
      if (_scale == null) {
        _scale = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<Offset>?, const Offset(1, 1));
      } else {
        _scale!.setValueCallback(callback as LottieValueCallback<Offset>?);
      }
    } else if (property == LottieProperty.transformRotation) {
      if (_rotation == null) {
        _rotation = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<double>?, 0.0);
      } else {
        _rotation!.setValueCallback(callback as LottieValueCallback<double>?);
      }
    } else if (property == LottieProperty.transformOpacity) {
      if (_opacity == null) {
        _opacity = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<int>?, 100);
      } else {
        _opacity!.setValueCallback(callback as LottieValueCallback<int>?);
      }
    } else if (property == LottieProperty.transformStartOpacity) {
      if (_startOpacity == null) {
        _startOpacity = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<double>?, 100);
      } else {
        _startOpacity!
            .setValueCallback(callback as LottieValueCallback<double>?);
      }
    } else if (property == LottieProperty.transformEndOpacity) {
      if (_endOpacity == null) {
        _endOpacity = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<double>?, 100);
      } else {
        _endOpacity!.setValueCallback(callback as LottieValueCallback<double>?);
      }
    } else if (property == LottieProperty.transformSkew) {
      _skew ??= DoubleKeyframeAnimation([Keyframe.nonAnimated(0.0)]);
      _skew!.setValueCallback(callback as LottieValueCallback<double>?);
    } else if (property == LottieProperty.transformSkewAngle) {
      _skewAngle ??= DoubleKeyframeAnimation([Keyframe.nonAnimated(0.0)]);
      _skewAngle!.setValueCallback(callback as LottieValueCallback<double>?);
    } else {
      return false;
    }

    return true;
  }
}
