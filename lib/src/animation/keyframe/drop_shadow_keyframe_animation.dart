import 'dart:ui';

import 'package:lottie/src/animation/keyframe/color_keyframe_animation.dart';
import 'package:lottie/src/model/content/drop_shadow_effect.dart';
import 'package:lottie/src/model/layer/base_layer.dart';
import 'package:lottie/src/value/lottie_value_callback.dart';
import 'dart:math' as math;
import 'base_keyframe_animation.dart';

class DropShadowKeyframeAnimation {
  static final double _degToRad = math.pi / 180.0;

  final void Function() listener;
  late final ColorKeyframeAnimation _color;
  late final BaseKeyframeAnimation<double, double> _opacity;
  late final BaseKeyframeAnimation<double, double> _direction;
  late final BaseKeyframeAnimation<double, double> _distance;
  late final BaseKeyframeAnimation<double, double> _radius;

  bool _isDirty = true;

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
    _isDirty = true;
    listener();
  }

  void draw(Canvas canvas, Path path) {
    if (!_isDirty) {
      //return;
    }
    _isDirty = false;

    double directionRad = _direction.value * _degToRad;
    double distance = _distance.value;
    double x = math.sin(directionRad) * distance;
    double y = math.cos(directionRad + math.pi) * distance;
    var baseColor = _color.value;
    var opacity = _opacity.value.round();
    var color = baseColor.withAlpha(opacity);
    var radius = _radius.value;
    //print("Radius $radius $opacity");

    var sigma = radius * 0.57735 + 0.5;

    var paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

    canvas.drawPath(path.shift(Offset(x, y)), paint);
  }

  void setColorCallback(LottieValueCallback<Color>? callback) {
    _color.setValueCallback(callback);
  }

  void setOpacityCallback(final LottieValueCallback<double>? callback) {
    if (callback == null) {
      _opacity.setValueCallback(null);
      return;
    }
    _opacity.setValueCallback(LottieValueCallback<double>(0)
      ..callback = (frameInfo) {
        var value = callback.getValue(frameInfo);
        if (value == null) {
          return 255;
        }
        // Convert [0,100] to [0,255] because other dynamic properties use [0,100].
        return value * 2.55;
      });
  }

  void setDirectionCallback(LottieValueCallback<double>? callback) {
    _direction.setValueCallback(callback);
  }

  void setDistanceCallback(LottieValueCallback<double>? callback) {
    _distance.setValueCallback(callback);
  }

  void setRadiusCallback(LottieValueCallback<double>? callback) {
    _radius.setValueCallback(callback);
  }
}
