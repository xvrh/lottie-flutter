import '../animation/keyframe/base_keyframe_animation.dart';
import 'lottie_frame_info.dart';

/// Allows you to set a callback on a resolved {@link com.airbnb.lottie.model.KeyPath} to modify
/// its animation values at runtime.
class LottieValueCallback<T> {
  LottieValueCallback(this._value);

  BaseKeyframeAnimation? _animation;
  BaseKeyframeAnimation? get animation => _animation;

  /// This can be set with {@link #setValue(Object)} to use a value instead of deferring
  /// to the callback.
  ///*/
  T? _value;
  T? get value => _value;

  T Function(LottieFrameInfo<T>)? callback;

  /// Override this if you haven't set a static value in the constructor or with setValue.
  ///
  /// Return null to resort to the default value.
  T? getValue(LottieFrameInfo<T> frameInfo) {
    if (callback != null) {
      return callback!(frameInfo);
    }

    return value;
  }

  void setValue(T? value) {
    _value = value;
    if (_animation != null) {
      _animation!.notifyListeners();
    }
  }

  T? getValueInternal(
      double startFrame,
      double? endFrame,
      T? startValue,
      T? endValue,
      double linearKeyframeProgress,
      double interpolatedKeyframeProgress,
      double overallProgress) {
    return getValue(LottieFrameInfo<T>(
        startFrame,
        endFrame,
        startValue,
        endValue,
        linearKeyframeProgress,
        interpolatedKeyframeProgress,
        overallProgress));
  }

  void setAnimation(BaseKeyframeAnimation? animation) {
    _animation = animation;
  }
}
