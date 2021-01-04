import '../../value/keyframe.dart';
import '../../value/lottie_value_callback.dart';
import 'base_keyframe_animation.dart';

class ValueCallbackKeyframeAnimation<K extends Object, A extends Object?>
    extends BaseKeyframeAnimation<K, A> {
  final A valueCallbackValue;

  ValueCallbackKeyframeAnimation(
      LottieValueCallback<A>? valueCallback, A valueCallbackValue)
      : valueCallbackValue = valueCallbackValue,
        super([]) {
    setValueCallback(valueCallback);
  }

  @override
  void setProgress(double progress) {
    this.progress = progress;
  }

  /// If this doesn't return 1, then {@link #setProgress(float)} will always clamp the progress
  /// to 0.
  @override
  double getEndProgress() {
    return 1.0;
  }

  @override
  void notifyListeners() {
    if (valueCallback != null) {
      super.notifyListeners();
    }
  }

  @override
  A get value {
    return valueCallback!.getValueInternal(0.0, 0.0, valueCallbackValue,
            valueCallbackValue, progress, progress, progress) ??
        valueCallbackValue;
  }

  @override
  A getValue(Keyframe<K> keyframe, double keyframeProgress) {
    return value;
  }
}
