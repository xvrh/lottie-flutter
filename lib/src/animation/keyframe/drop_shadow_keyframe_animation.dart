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

  Paint? _paint;

  DropShadowKeyframeAnimation(
      this.listener, BaseLayer layer, DropShadowEffect dropShadowEffect) {
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
    _paint = null;
    listener();
  }

  void draw(Canvas canvas, Path path) {
    var directionRad = _direction.value * _degToRad;
    var distance = _distance.value;
    var x = math.sin(directionRad) * distance;
    var y = math.cos(directionRad + math.pi) * distance;
    var baseColor = _color.value;
    var opacity = _opacity.value.round();
    var color = baseColor.withAlpha(opacity);
    var radius = _radius.value;

    var sigma = radius * 0.57735 + 0.5;

    var paint = _paint;
    paint ??= _paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

    canvas.drawPath(path.shift(Offset(x, y)), paint);
  }

  void setCallback(LottieValueCallback<DropShadow>? callback) {
    if (callback != null) {
      _color.setValueCallback(_createCallback(
          callback, (c) => c?.color ?? const Color(0xff000000)));
      _opacity
          .setValueCallback(_createCallback(callback, (c) => c?.color.a ?? 1));
      _direction.setValueCallback(
          _createCallback(callback, (c) => c?.direction ?? 0));
      _distance
          .setValueCallback(_createCallback(callback, (c) => c?.distance ?? 0));
      _radius
          .setValueCallback(_createCallback(callback, (c) => c?.radius ?? 0));
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
      T Function(DropShadow?) selector) {
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
