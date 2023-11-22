import 'package:flutter/animation.dart';
import '../composition.dart';

class Keyframe<T> {
  final LottieComposition? _composition;
  final T? startValue;
  T? endValue;
  final Curve? interpolator;
  final Curve? xInterpolator;
  final Curve? yInterpolator;
  final double startFrame;
  double? endFrame;

  double _startProgress = double.minPositive;
  double _endProgress = double.minPositive;

  // Used by PathKeyframe but it has to be parsed by KeyFrame because we use a JsonReader to
  // deserialzie the data so we have to parse everything in order
  Offset? pathCp1;
  Offset? pathCp2;

  Keyframe(this._composition,
      {required this.startValue,
      this.endValue,
      this.interpolator,
      this.xInterpolator,
      this.yInterpolator,
      double? startFrame,
      this.endFrame})
      : startFrame = startFrame ?? 0.0;

  /// Non-animated value.
  Keyframe.nonAnimated(T value)
      : _composition = null,
        startValue = value,
        endValue = value,
        interpolator = null,
        startFrame = double.minPositive,
        endFrame = double.maxFinite,
        xInterpolator = null,
        yInterpolator = null;

  Keyframe._(this.startValue, this.endValue)
      : _composition = null,
        interpolator = null,
        xInterpolator = null,
        yInterpolator = null,
        startFrame = double.minPositive,
        endFrame = double.maxFinite;

  Keyframe<T> copyWith(T startValue, T endValue) {
    return Keyframe<T>._(startValue, endValue);
  }

  double get startProgress {
    if (_composition == null) {
      return 0.0;
    }
    if (_startProgress == double.minPositive) {
      _startProgress =
          (startFrame - _composition.startFrame) / _composition.durationFrames;
    }
    return _startProgress;
  }

  double get endProgress {
    if (_composition == null) {
      return 1.0;
    }
    if (_endProgress == double.minPositive) {
      if (endFrame == null) {
        _endProgress = 1.0;
      } else {
        var durationFrames = endFrame! - startFrame;
        var durationProgress = durationFrames / _composition.durationFrames;
        _endProgress = startProgress + durationProgress;
      }
    }
    return _endProgress;
  }

  bool get isStatic {
    return interpolator == null &&
        xInterpolator == null &&
        yInterpolator == null;
  }

  bool containsProgress(double progress) {
    return progress >= startProgress && progress < endProgress;
  }

  @override
  String toString() {
    return 'Keyframe{'
        'startValue=$startValue'
        ', endValue=$endValue'
        ', startFrame=$startFrame'
        ', endFrame=$endFrame'
        ', interpolator=$interpolator'
        '}';
  }
}
