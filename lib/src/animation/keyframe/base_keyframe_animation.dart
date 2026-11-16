import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../../l.dart';
import '../../model/keyframe_loop.dart';
import '../../utils/path_interpolator.dart';
import '../../value/keyframe.dart';
import '../../value/lottie_value_callback.dart';

/// @param K Keyframe type
/// @param A Animation type
abstract class BaseKeyframeAnimation<K extends Object, A extends Object?> {
  // This is not a Set because we don't want to create an iterator object on every setProgress.
  final listeners = <void Function()>[];
  bool _isDiscrete = false;
  bool _notifiesInConstantKeyframes = false;

  final _KeyframesWrapper<K> _keyframesWrapper;
  double _progress = 0;
  LottieValueCallback<A>? valueCallback;

  /// The keyframes repeated by a `loopOut` or `loopIn` expression.
  final _Loop? _loop;

  A? _cachedGetValue;

  double _cachedStartDelayProgress = -1.0;
  double _cachedEndProgress = -1.0;

  BaseKeyframeAnimation(List<Keyframe<K>> keyframes, {KeyframeLoop? loop})
    : _keyframesWrapper = _wrap(keyframes),
      _loop = loop == null ? null : _Loop(loop);

  void setIsDiscrete() {
    _isDiscrete = true;
  }

  /// Keeps notifying the listeners while the progress moves inside a keyframe
  /// whose start and end values are equal, for a listener that reads more than
  /// [value] at the current progress.
  void setNotifiesInConstantKeyframes() {
    _notifiesInConstantKeyframes = true;
  }

  void addUpdateListener(void Function() listener) {
    listeners.add(listener);
  }

  void setProgress(double progress) {
    if (_keyframesWrapper.isEmpty) {
      return;
    }
    if (_loop case var loop?) {
      _setLoopProgress(loop, progress);
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
    // A value callback receives the progress inside the keyframe, so its result
    // can change even when the keyframe values are equal.
    var ignoreConstantKeyframes =
        valueCallback == null && !_notifiesInConstantKeyframes;
    if (_keyframesWrapper.isValueChanged(
      progress,
      ignoreConstantKeyframes: ignoreConstantKeyframes,
    )) {
      notifyListeners();
    }
  }

  /// [setProgress] for keyframes that [loop] repeats: [progress] is only
  /// clamped to the keyframes where the loop doesn't play.
  void _setLoopProgress(_Loop loop, double progress) {
    var position = loop.position;
    var previousKeyframeProgress = position.keyframeProgress;
    var previousRepetition = position.repetition;
    var previousTimes = position.times;
    if (!position.moveTo(progress)) {
      if (progress < getStartDelayProgress()) {
        progress = getStartDelayProgress();
      } else if (progress > getEndProgress()) {
        progress = getEndProgress();
      }
      position.keyframeProgress = progress;
    }
    var keyframeProgress = position.keyframeProgress;
    if (progress == _progress &&
        keyframeProgress == previousKeyframeProgress &&
        position.repetition == previousRepetition &&
        position.times == previousTimes) {
      return;
    }
    _progress = progress;
    var ignoreConstantKeyframes =
        valueCallback == null && !_notifiesInConstantKeyframes;
    // The keyframes can be read at the same progress again, e.g. at the end of
    // the last one for `continue`.
    var changed =
        (keyframeProgress != previousKeyframeProgress ||
            valueCallback != null) &&
        _keyframesWrapper.isValueChanged(
          keyframeProgress,
          ignoreConstantKeyframes: ignoreConstantKeyframes,
        );
    // Other keyframes may have played in between, so this move can't tell that
    // the frames it jumps over look the same (see `FrameChanges.observe`).
    if (position.repetition != previousRepetition) {
      changed = true;
    }
    if (!changed && position.times != previousTimes) {
      var (from, to) = _getLoopEnds(loop);
      changed = valueCallback != null || from != to;
    }
    if (changed) {
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
    return _linearProgressIn(
      getCurrentKeyframe(),
      _loop?.position.keyframeProgress ?? _progress,
    );
  }

  double _linearProgressIn(Keyframe<K> keyframe, double keyframeProgress) {
    if (keyframe.isStatic) {
      return 0.0;
    }
    var progressIntoFrame = keyframeProgress - keyframe.startProgress;
    var keyframeLength = keyframe.endProgress - keyframe.startProgress;
    return (progressIntoFrame / keyframeLength).clamp(0, 1);
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

    var loop = _loop;
    var linearProgress = getLinearCurrentKeyframeProgress();
    if (valueCallback == null &&
        _keyframesWrapper.isCachedValueEnabled(linearProgress) &&
        !skipCache &&
        (loop == null || loop.cachedTimes == loop.position.times)) {
      return _cachedGetValue!;
    }

    loop?.valueFromCallback = false;
    final keyframe = getCurrentKeyframe();
    if (keyframe.xInterpolator != null && keyframe.yInterpolator != null) {
      var xProgress = keyframe.xInterpolator!.transform(linearProgress);
      var yProgress = keyframe.yInterpolator!.transform(linearProgress);
      value = getValueSplitDimension(
        keyframe,
        linearProgress,
        xProgress,
        yProgress,
      );
    } else {
      var progress = getInterpolatedCurrentKeyframeProgress();
      value = getValue(keyframe, progress);
    }
    if (loop != null) {
      // A value callback was given the keyframe values as the loop moves them.
      if (!loop.valueFromCallback) {
        value = _addLoopDifference(loop, value);
      }
      loop.cachedTimes = loop.position.times;
    }

    _cachedGetValue = value;

    return value;
  }

  /// The value of [valueCallback] for the current keyframe, whose values are
  /// [startValue] and [endValue], or null if it gives none.
  ///
  /// The callback is given the keyframe values where the loop plays them: the
  /// `offset` and `continue` loops move them, so that a callback relative to
  /// them follows the loop.
  @protected
  A? getValueFromCallback(
    double startFrame,
    double? endFrame,
    A? startValue,
    A? endValue,
    double linearKeyframeProgress,
    double interpolatedKeyframeProgress,
  ) {
    var loop = _loop;
    if (loop != null) {
      startValue = _addLoopDifference(loop, startValue);
      endValue = _addLoopDifference(loop, endValue);
    }
    var value = valueCallback!.getValueInternal(
      startFrame,
      endFrame,
      startValue,
      endValue,
      linearKeyframeProgress,
      interpolatedKeyframeProgress,
      progress,
    );
    if (value != null && loop != null) {
      loop.valueFromCallback = true;
    }
    return value;
  }

  /// Adds [LoopPosition.times] the difference between the values at the ends
  /// of [loop] to [value], for the `offset` and `continue` loops.
  T _addLoopDifference<T>(_Loop loop, T value) {
    var times = loop.position.times;
    if (times == 0) {
      return value;
    }
    var result = switch ((value, _getLoopEnds(loop))) {
      (int base, (num from, num to)) => (base + (to - from) * times).round(),
      (double base, (num from, num to)) => base + (to - from) * times,
      (Offset base, (Offset from, Offset to)) => base + (to - from) * times,
      _ => value,
    };
    return result as T;
  }

  /// The two values of the keyframes whose difference [LoopPosition.times]
  /// counts.
  (Object?, Object?) _getLoopEnds(_Loop loop) {
    return loop.ends ??= loop.position.loop.type == LoopType.continueMotion
        ? _continueEnds(loop.position.loop)
        : (
            _loopValueAt(loop.position.loop.startProgress),
            _loopValueAt(loop.position.loop.endProgress),
          );
  }

  /// The value of the keyframes at [keyframeProgress].
  Object? _loopValueAt(double keyframeProgress) {
    var keyframe = _keyframesWrapper.keyframeAt(keyframeProgress);
    var linearProgress = _isDiscrete
        ? 0.0
        : _linearProgressIn(keyframe, keyframeProgress);
    return _easedLoopValue(
      keyframe,
      (curve) => curve.transform(linearProgress),
    );
  }

  /// The values at the end of the keyframe whose velocity `continue` keeps
  /// (at the start for `loopIn`), and [KeyframeLoop.continueStep] of the
  /// keyframe before it (after it), on the tangent of its easing.
  (Object?, Object?) _continueEnds(KeyframeLoop loop) {
    var keyframe = _keyframesWrapper.keyframeAt(loop.continuedKeyframe);
    var (end, step) = loop.isOut
        ? (1.0, -KeyframeLoop.continueStep)
        : (0.0, KeyframeLoop.continueStep);
    return (
      _easedLoopValue(keyframe, (curve) => _easeNear(curve, end, step)),
      _easedLoopValue(keyframe, (curve) => end),
    );
  }

  /// [getLoopValue] for [keyframe], whose easing curves [ease] applies to.
  Object? _easedLoopValue(Keyframe<K> keyframe, double Function(Curve) ease) {
    if (keyframe.xInterpolator case var xInterpolator?) {
      if (keyframe.yInterpolator case var yInterpolator?) {
        return getLoopValue(keyframe, ease(xInterpolator), ease(yInterpolator));
      }
    }
    var interpolator = keyframe.interpolator;
    var progress = keyframe.isStatic || interpolator == null
        ? 0.0
        : ease(interpolator);
    return getLoopValue(keyframe, progress, progress);
  }

  /// [curve] at [step] from its [end] (0 or 1). The samples of a
  /// [PathInterpolator] are too coarse there for a velocity: its tangent at
  /// [end] gives it instead.
  static double _easeNear(Curve curve, double end, double step) {
    if (curve is PathInterpolator) {
      var slope = end == 0 ? curve.startSlope : curve.endSlope;
      if (slope.isFinite) {
        return end + step * slope;
      }
    }
    return curve.transform(end + step);
  }

  /// The progress given to [setProgress], clamped to the keyframes except
  /// where a `loopOut` or `loopIn` expression repeats them: it goes on there,
  /// beyond the keyframes.
  double get progress {
    return _progress;
  }

  @protected
  set progress(double value) {
    _progress = value;
  }

  /// The repetition of the keyframes that a `loopOut` or `loopIn` expression
  /// plays at [progress] (see [LoopPosition.repetition]), 0 if none does.
  int get loopRepetition => _loop?.position.repetition ?? 0;

  void setValueCallback(LottieValueCallback<A>? valueCallback) {
    if (this.valueCallback != null) {
      this.valueCallback!.setAnimation(null);
    }
    this.valueCallback = valueCallback;
    if (valueCallback != null) {
      valueCallback.setAnimation(this);
    }
  }

  bool get hasValueCallback => valueCallback != null;

  @protected
  bool get skipCache => false;

  /// keyframeProgress will be [0, 1] unless the interpolator has overshoot in which case, this
  /// should be able to handle values outside of that range.
  A getValue(Keyframe<K> keyframe, double keyframeProgress);

  /// The value of [keyframe] at the eased progress [xProgress] ([yProgress]
  /// for the vertical dimension of a point whose dimensions ease apart),
  /// without the value callback, for the `offset` and `continue` loops to add
  /// up: a number or an [Offset]. An integer is not rounded.
  ///
  /// Null for values that can't be added up, which these loops don't play.
  @protected
  Object? getLoopValue(
    Keyframe<K> keyframe,
    double xProgress,
    double yProgress,
  ) => null;

  A getValueSplitDimension(
    Keyframe<K> keyframe,
    double linearKeyframeProgress,
    double xKeyframeProgress,
    double yKeyframeProgress,
  ) {
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

  /// Whether moving to [progress] can change the value. With
  /// [ignoreConstantKeyframes], moving inside a keyframe whose start and end
  /// values are equal doesn't count as a change.
  bool isValueChanged(double progress, {required bool ignoreConstantKeyframes});

  Keyframe<T> getCurrentKeyframe();

  /// The keyframe that plays at [progress], without changing the current one.
  Keyframe<T> keyframeAt(double progress);

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
  bool isValueChanged(
    double progress, {
    required bool ignoreConstantKeyframes,
  }) {
    return false;
  }

  @override
  Keyframe<T> getCurrentKeyframe() {
    throw StateError('not implemented');
  }

  @override
  Keyframe<T> keyframeAt(double progress) {
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
  bool isValueChanged(
    double progress, {
    required bool ignoreConstantKeyframes,
  }) {
    return !(ignoreConstantKeyframes ? keyframe.isConstant : keyframe.isStatic);
  }

  @override
  Keyframe<T> getCurrentKeyframe() {
    return keyframe;
  }

  @override
  Keyframe<T> keyframeAt(double progress) {
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
  bool isValueChanged(
    double progress, {
    required bool ignoreConstantKeyframes,
  }) {
    var keyframe = _currentKeyframe!;
    if (keyframe.containsProgress(progress)) {
      return !(ignoreConstantKeyframes
          ? keyframe.isConstant
          : keyframe.isStatic);
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
  Keyframe<T> keyframeAt(double progress) {
    for (var i = keyframes.length - 1; i > 0; i--) {
      if (progress >= keyframes[i].startProgress) {
        return keyframes[i];
      }
    }
    return keyframes.first;
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

/// The state of a [KeyframeLoop] in an animation.
class _Loop {
  _Loop(KeyframeLoop loop) : position = LoopPosition(loop);

  final LoopPosition position;

  /// The two values whose difference [LoopPosition.times] counts.
  (Object?, Object?)? ends;

  /// [LoopPosition.times] when the cached value was computed.
  double cachedTimes = 0;

  /// Whether the value callback gave the value being computed.
  bool valueFromCallback = false;
}
