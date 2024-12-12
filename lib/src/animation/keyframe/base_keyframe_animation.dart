import 'package:flutter/foundation.dart';
import '../../l.dart';
import '../../value/keyframe.dart';
import '../../value/lottie_value_callback.dart';

/// @param K Keyframe type
/// @param A Animation type
abstract class BaseKeyframeAnimation<K extends Object, A extends Object?> {
// This is not a Set because we don't want to create an iterator object on every setProgress.
  final listeners = <void Function()>[];
  bool _isDiscrete = false;

  final _KeyframesWrapper<K> _keyframesWrapper;
  double _progress = 0;
  LottieValueCallback<A>? valueCallback;

  A? _cachedGetValue;

  double _cachedStartDelayProgress = -1.0;
  double _cachedEndProgress = -1.0;

  BaseKeyframeAnimation(List<Keyframe<K>> keyframes)
      : _keyframesWrapper = _wrap(keyframes);

  void setIsDiscrete() {
    _isDiscrete = true;
  }

  void addUpdateListener(void Function() listener) {
    listeners.add(listener);
  }

  void setProgress(double progress) {
    if (_keyframesWrapper.isEmpty) {
      return;
    }
    if (progress < getStartDelayProgress()) {
      progress = getStartDelayProgress();
    } else if (progress > getEndProgress()) {
      progress = getEndProgress();
    }

    if (progress == _progress) {
      return;
    }
    _progress = progress;
    if (_keyframesWrapper.isValueChanged(progress)) {
      notifyListeners();
    }
  }

  void notifyListeners() {
    for (var listener in listeners) {
      listener();
    }
  }

  Keyframe<K> getCurrentKeyframe() {
    L.beginSection('BaseKeyframeAnimation#getCurrentKeyframe');
    final keyframe = _keyframesWrapper.getCurrentKeyframe();
    L.endSection('BaseKeyframeAnimation#getCurrentKeyframe');
    return keyframe;
  }

  /// Returns the progress into the current keyframe between 0 and 1. This does not take into account
  /// any interpolation that the keyframe may have.
  double getLinearCurrentKeyframeProgress() {
    if (_isDiscrete) {
      return 0.0;
    }

    var keyframe = getCurrentKeyframe();
    if (keyframe.isStatic) {
      return 0.0;
    }
    var progressIntoFrame = _progress - keyframe.startProgress;
    var keyframeProgress = keyframe.endProgress - keyframe.startProgress;
    return (progressIntoFrame / keyframeProgress).clamp(0, 1);
  }

  /// Takes the value of {@link #getLinearCurrentKeyframeProgress()} and interpolates it with
  /// the current keyframe's interpolator.
  double getInterpolatedCurrentKeyframeProgress() {
    var keyframe = getCurrentKeyframe();
    if (keyframe.isStatic || keyframe.interpolator == null) {
      return 0.0;
    }
    return keyframe.interpolator!.transform(getLinearCurrentKeyframeProgress());
  }

  double getStartDelayProgress() {
    if (_cachedStartDelayProgress == -1) {
      _cachedStartDelayProgress = _keyframesWrapper.getStartDelayProgress();
    }
    return _cachedStartDelayProgress;
  }

  double getEndProgress() {
    if (_cachedEndProgress == -1) {
      _cachedEndProgress = _keyframesWrapper.getEndProgress();
    }
    return _cachedEndProgress;
  }

  A get value {
    A value;

    var linearProgress = getLinearCurrentKeyframeProgress();
    if (valueCallback == null &&
        _keyframesWrapper.isCachedValueEnabled(linearProgress)) {
      return _cachedGetValue!;
    }

    final keyframe = getCurrentKeyframe();
    if (keyframe.xInterpolator != null && keyframe.yInterpolator != null) {
      var xProgress = keyframe.xInterpolator!.transform(linearProgress);
      var yProgress = keyframe.yInterpolator!.transform(linearProgress);
      value = getValueSplitDimension(
          keyframe, linearProgress, xProgress, yProgress);
    } else {
      var progress = getInterpolatedCurrentKeyframeProgress();
      value = getValue(keyframe, progress);
    }

    _cachedGetValue = value;

    return value;
  }

  double get progress {
    return _progress;
  }

  @protected
  set progress(double value) {
    _progress = value;
  }

  void setValueCallback(LottieValueCallback<A>? valueCallback) {
    if (this.valueCallback != null) {
      this.valueCallback!.setAnimation(null);
    }
    this.valueCallback = valueCallback;
    if (valueCallback != null) {
      valueCallback.setAnimation(this);
    }
  }

  /// keyframeProgress will be [0, 1] unless the interpolator has overshoot in which case, this
  /// should be able to handle values outside of that range.
  A getValue(Keyframe<K> keyframe, double keyframeProgress);

  A getValueSplitDimension(Keyframe<K> keyframe, double linearKeyframeProgress,
      double xKeyframeProgress, double yKeyframeProgress) {
    throw Exception('This animation does not support split dimensions!');
  }

  static _KeyframesWrapper<T> _wrap<T>(List<Keyframe<T>> keyframes) {
    if (keyframes.isEmpty) {
      return _EmptyKeyframeWrapper();
    }
    if (keyframes.length == 1) {
      return _SingleKeyframeWrapper(keyframes);
    }
    return _KeyframesWrapperImpl(keyframes);
  }
}

abstract class _KeyframesWrapper<T> {
  bool get isEmpty;

  bool isValueChanged(double progress);

  Keyframe<T> getCurrentKeyframe();

  double getStartDelayProgress();

  double getEndProgress();

  bool isCachedValueEnabled(double progress);
}

class _EmptyKeyframeWrapper<T> implements _KeyframesWrapper<T> {
  @override
  bool get isEmpty {
    return true;
  }

  @override
  bool isValueChanged(double progress) {
    return false;
  }

  @override
  Keyframe<T> getCurrentKeyframe() {
    throw StateError('not implemented');
  }

  @override
  double getStartDelayProgress() {
    return 0;
  }

  @override
  double getEndProgress() {
    return 1;
  }

  @override
  bool isCachedValueEnabled(double progress) {
    throw StateError('not implemented');
  }
}

class _SingleKeyframeWrapper<T> implements _KeyframesWrapper<T> {
  final Keyframe<T> keyframe;
  double _cachedInterpolatedProgress = -1;

  _SingleKeyframeWrapper(List<Keyframe<T>> keyframes)
      : keyframe = keyframes.first;

  @override
  bool get isEmpty {
    return false;
  }

  @override
  bool isValueChanged(double progress) {
    return !keyframe.isStatic;
  }

  @override
  Keyframe<T> getCurrentKeyframe() {
    return keyframe;
  }

  @override
  double getStartDelayProgress() {
    return keyframe.startProgress;
  }

  @override
  double getEndProgress() {
    return keyframe.endProgress;
  }

  @override
  bool isCachedValueEnabled(double progress) {
    if (_cachedInterpolatedProgress == progress) {
      return true;
    }
    _cachedInterpolatedProgress = progress;
    return false;
  }
}

class _KeyframesWrapperImpl<T> implements _KeyframesWrapper<T> {
  final List<Keyframe<T>> keyframes;
  Keyframe<T>? _currentKeyframe;
  Keyframe<T>? _cachedCurrentKeyframe;
  double _cachedInterpolatedProgress = -1;

  _KeyframesWrapperImpl(this.keyframes) {
    _currentKeyframe = findKeyframe(0);
  }

  @override
  bool get isEmpty {
    return false;
  }

  @override
  bool isValueChanged(double progress) {
    if (_currentKeyframe!.containsProgress(progress)) {
      return !_currentKeyframe!.isStatic;
    }
    _currentKeyframe = findKeyframe(progress);
    return true;
  }

  Keyframe<T> findKeyframe(double progress) {
    var keyframe = keyframes.last;
    if (progress >= keyframe.startProgress) {
      return keyframe;
    }
    for (var i = keyframes.length - 2; i >= 1; i--) {
      keyframe = keyframes[i];
      if (_currentKeyframe == keyframe) {
        continue;
      }
      if (keyframe.containsProgress(progress)) {
        return keyframe;
      }
    }
    return keyframes.first;
  }

  @override
  Keyframe<T> getCurrentKeyframe() {
    return _currentKeyframe!;
  }

  @override
  double getStartDelayProgress() {
    return keyframes.first.startProgress;
  }

  @override
  double getEndProgress() {
    return keyframes.last.endProgress;
  }

  @override
  bool isCachedValueEnabled(double progress) {
    if (_cachedCurrentKeyframe == _currentKeyframe &&
        _cachedInterpolatedProgress == progress) {
      return true;
    }
    _cachedCurrentKeyframe = _currentKeyframe;
    _cachedInterpolatedProgress = progress;
    return false;
  }
}
