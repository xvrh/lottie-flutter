import '../animation/keyframe/base_keyframe_animation.dart';
import 'lottie_frame_info.dart';

/// Allows you to set a callback on a resolved {@link com.airbnb.lottie.model.KeyPath} to modify
/// its animation values at runtime.
class LottieValueCallback<T> {
  BaseKeyframeAnimation /*?*/ animation;

  /// This can be set with {@link #setValue(Object)} to use a value instead of deferring
  /// to the callback.
  ///*/
  T /*?*/ value;

  LottieValueCallback(this.value);

  /// Override this if you haven't set a static value in the constructor or with setValue.
  ///
  /// Return null to resort to the default value.
  T getValue(LottieFrameInfo<T> frameInfo) {
    return value;
  }

  void setValue(T /*?*/ value) {
    this.value = value;
    if (animation != null) {
      animation.notifyListeners();
    }
  }

  T /*?*/ getValueInternal(
      double startFrame,
      double endFrame,
      T startValue,
      T endValue,
      double linearKeyframeProgress,
      double interpolatedKeyframeProgress,
      double overallProgress) {
    return getValue(LottieFrameInfo(startFrame, endFrame, startValue, endValue,
        linearKeyframeProgress, interpolatedKeyframeProgress, overallProgress));
  }

  void setAnimation(BaseKeyframeAnimation /*?*/ animation) {
    this.animation = animation;
  }
}
