import 'dart:math' as math;
import 'dart:ui';
import '../../lottie_property.dart';
import '../../model/content/drop_shadow_effect.dart';
import '../../model/layer/base_layer.dart';
import '../../value/drop_shadow.dart';
import '../../value/lottie_frame_info.dart';
import '../../value/lottie_value_callback.dart';
import 'base_keyframe_animation.dart';
import 'color_keyframe_animation.dart';

class DropShadowKeyframeAnimation {
  static const double _degToRad = math.pi / 180.0;

  final void Function() listener;
  late final ColorKeyframeAnimation _color;
  late final BaseKeyframeAnimation<double, double> _opacity;
  late final BaseKeyframeAnimation<double, double> _direction;
  late final BaseKeyframeAnimation<double, double> _distance;
  late final BaseKeyframeAnimation<double, double> _radius;

  DropShadowKeyframeAnimation(
    this.listener,
    BaseLayer layer,
    DropShadowEffect dropShadowEffect,
  ) {
    _color = dropShadowEffect.color.createAnimation()
      ..addUpdateListener(onValueChanged);
    layer.addAnimation(_color);
    _opacity = dropShadowEffect.opacity.createAnimation()
      ..addUpdateListener(onValueChanged);
    layer.addAnimation(_opacity);
    _direction = dropShadowEffect.direction.createAnimation()
      ..addUpdateListener(onValueChanged);
    layer.addAnimation(_direction);
    _distance = dropShadowEffect.distance.createAnimation()
      ..addUpdateListener(onValueChanged);
    layer.addAnimation(_distance);
    _radius = dropShadowEffect.radius.createAnimation()
      ..addUpdateListener(onValueChanged);
    layer.addAnimation(_radius);
  }

  void onValueChanged() {
    listener();
  }

  bool get isVisible {
    return _opacity.value > 0 &&
        (_radius.value > 0 || _distance.value.abs() > 0);
  }

  Offset get offset {
    var directionRad = _direction.value * _degToRad;
    var distance = _distance.value;
    return Offset(
      math.sin(directionRad) * distance,
      math.cos(directionRad + math.pi) * distance,
    );
  }

  /// Softness converted with the same radius-to-sigma factor as layer blur.
  double get sigma {
    var radius = _radius.value;
    if (radius <= 0) {
      return 0;
    }
    return radius * 0.57735 + 0.5;
  }

  /// Lottie drop-shadow opacity is 0–255. [ValueDelegate] supplies a [Color]
  /// whose alpha is 0–1, scaled back to that range in [setCallback].
  Color get color {
    var opacity = (_opacity.value / 255).clamp(0.0, 1.0);
    return _color.value.withValues(alpha: opacity);
  }

  void setCallback(LottieValueCallback<DropShadow>? callback) {
    if (callback != null) {
      _color.setValueCallback(
        _createCallback(callback, (c) => c?.color ?? const Color(0xff000000)),
      );
      _opacity.setValueCallback(
        _createCallback(callback, (c) => (c?.color.a ?? 1) * 255),
      );
      _direction.setValueCallback(
        _createCallback(callback, (c) => c?.direction ?? 0),
      );
      _distance.setValueCallback(
        _createCallback(callback, (c) => c?.distance ?? 0),
      );
      _radius.setValueCallback(
        _createCallback(callback, (c) => c?.radius ?? 0),
      );
    } else {
      _color.setValueCallback(null);
      _opacity.setValueCallback(null);
      _direction.setValueCallback(null);
      _distance.setValueCallback(null);
      _radius.setValueCallback(null);
    }
  }

  LottieValueCallback<T> _createCallback<T>(
    LottieValueCallback<DropShadow> callback,
    T Function(DropShadow?) selector,
  ) {
    return LottieValueCallback<T>(null)
      ..callback = (info) {
        onValueChanged();
        var frameInfo = LottieFrameInfo<DropShadow>(
          info.startFrame,
          info.endFrame,
          LottieProperty.dropShadow,
          LottieProperty.dropShadow,
          info.linearKeyframeProgress,
          info.interpolatedKeyframeProgress,
          info.overallProgress,
        );
        var dropShadow = callback.getValue(frameInfo);
        return selector(dropShadow);
      };
  }
}
