import 'dart:ui';
import '../../value/keyframe.dart';
import 'base_keyframe_animation.dart';

class SplitDimensionPathKeyframeAnimation
    extends BaseKeyframeAnimation<Offset, Offset> {
  late Offset _point;
  final BaseKeyframeAnimation<double, double> _xAnimation;
  final BaseKeyframeAnimation<double, double> _yAnimation;

  SplitDimensionPathKeyframeAnimation(this._xAnimation, this._yAnimation)
      : super(<Keyframe<Offset>>[]) {
    // We need to call an initial setProgress so point gets set with the initial value.
    setProgress(progress);
  }

  @override
  void setProgress(double progress) {
    _xAnimation.setProgress(progress);
    _yAnimation.setProgress(progress);
    _point = Offset(_xAnimation.value, _yAnimation.value);
    for (var i = 0; i < listeners.length; i++) {
      listeners[i]();
    }
  }

  @override
  Offset get value {
    return _point;
  }

  @override
  Offset getValue(Keyframe<Offset> keyframe, double keyframeProgress) {
    return _point;
  }
}
