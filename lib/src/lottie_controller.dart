import 'dart:async';
import 'package:flutter/animation.dart';

/// A custom animation controller that drives animations using [Timer.periodic]
/// instead of Flutter's Ticker/Vsync mechanism.
///
/// This allows precise frame rate control for Lottie animations, which is
/// particularly useful on LTPO devices (like HarmonyOS) where Vsync intervals
/// may be unstable.
///
/// [LottieController] implements [Animation<double>] and provides an API
/// compatible with [AnimationController] for most common use cases:
/// - [forward], [reverse], [stop], [reset]
/// - [repeat] with min/max/reverse/period/count
/// - [animateTo] with duration and curve
/// - [value] getter/setter
/// - [addListener], [addStatusListener]
/// - [duration], [isAnimating], [status]
///
/// **Limitations compared to [AnimationController]:**
/// - [fling] and [animateWith] are not supported (requires physics simulation)
/// - [TickerFuture] is not returned from control methods; use [addStatusListener]
///   or the [completed] Future getter instead.
///
/// Example usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> {
///   late final LottieController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = LottieController()
///       ..addListener(() => setState(() {}));
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Lottie.asset(
///       'assets/animation.json',
///       controller: _controller,
///     );
///   }
/// }
/// ```
class LottieController extends Animation<double>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  /// Creates a [LottieController].
  ///
  /// [value] is the initial progress (0.0 to 1.0).
  /// [duration] is the total duration of one full animation cycle.
  /// [reverseDuration] is used when playing in reverse (defaults to [duration]).
  /// [lowerBound] and [upperBound] clamp the value range (default 0.0 to 1.0).
  /// [targetFps] controls the Timer tick frequency (default 60).
  LottieController({
    double? value,
    this.duration,
    this.reverseDuration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    this.debugLabel,
    int? targetFps,
  }) : _targetFps = targetFps ?? 60 {
    assert(lowerBound <= upperBound);
    if (_targetFps <= 0) {
      throw ArgumentError('targetFps must be greater than 0');
    }
    _internalSetValue(value ?? lowerBound);
  }

  // ===========================================================================
  // Public Properties
  // ===========================================================================

  /// The duration of one full forward animation cycle.
  Duration? duration;

  /// The duration of one full reverse animation cycle.
  /// If null, [duration] is used.
  Duration? reverseDuration;

  /// The minimum value for the animation (default 0.0).
  final double lowerBound;

  /// The maximum value for the animation (default 1.0).
  final double upperBound;

  /// A debug label for this controller.
  final String? debugLabel;

  /// The target frames per second for the Timer tick.
  int get targetFps => _targetFps;
  set targetFps(int value) {
    assert(value > 0);
    if (_targetFps == value) return;
    _targetFps = value;
    // Restart timer if currently running to apply new frequency
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      final now = DateTime.now();
      if (_startTime != null) {
        _elapsedAtLastStart += now.difference(_startTime!);
      }
      _startTime = now;
      if (_animateDuration != null) {
        _timer = Timer.periodic(_tickInterval, _onAnimateTick);
      } else if (_repeatPeriod != null) {
        _timer = Timer.periodic(_tickInterval, _onRepeatTick);
      }
    }
  }

  // ===========================================================================
  // Animation<double> Interface
  // ===========================================================================

  @override
  double get value => _value;

  set value(double newValue) {
    if (_disposed) {
      throw StateError('Cannot set value on a disposed LottieController');
    }
    stop();
    _internalSetValue(newValue);
    if (_disposed) return;
    notifyListeners();
    _checkStatusChanged();
  }

  @override
  AnimationStatus get status => _status;

  @override
  bool get isAnimating => _isAnimating;

  @override
  bool get isDismissed => status == AnimationStatus.dismissed;

  @override
  bool get isCompleted => status == AnimationStatus.completed;

  // ===========================================================================
  // Control Methods
  // ===========================================================================

  /// Starts playing the animation forward (from current value to [upperBound]).
  void forward({double? from}) {
    _assertNotDisposed();
    _direction = _AnimationDirection.forward;
    if (from != null) {
      _internalSetValue(from);
    }
    _animateToInternal(upperBound, duration: duration);
  }

  /// Starts playing the animation in reverse (from current value to [lowerBound]).
  void reverse({double? from}) {
    _assertNotDisposed();
    _direction = _AnimationDirection.reverse;
    if (from != null) {
      _internalSetValue(from);
    }
    _animateToInternal(lowerBound, duration: reverseDuration ?? duration);
  }

  /// Animates to a specific target value with optional duration and curve.
  void animateTo(
    double target, {
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    _assertNotDisposed();
    _direction = target >= _value
        ? _AnimationDirection.forward
        : _AnimationDirection.reverse;
    _animateToInternal(
      target.clamp(lowerBound, upperBound),
      duration: duration ?? this.duration,
      curve: curve,
    );
  }

  /// Starts a repeating animation.
  void repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  }) {
    _assertNotDisposed();
    if (period == null && duration == null) {
      throw ArgumentError('Either period or duration must be specified');
    }

    stop();
    _repeatMin = (min ?? lowerBound).clamp(lowerBound, upperBound);
    _repeatMax = (max ?? upperBound).clamp(lowerBound, upperBound);
    _repeatReverse = reverse;
    _repeatPeriod = period ?? duration!;
    _repeatCount = count;
    _direction = _AnimationDirection.forward;

    if (count != null && count <= 0) {
      // Nothing to do, reset state to avoid pollution
      stop();
      _repeatMin = null;
      _repeatMax = null;
      _repeatReverse = false;
      _repeatPeriod = null;
      _repeatCount = null;
      return;
    }

    _startTimer(_repeatPeriod!, _onRepeatTick);
  }

  /// Stops the animation at the current value.
  void stop({bool canceled = true}) {
    _timer?.cancel();
    _timer = null;
    _isAnimating = false;

    if (_completeCompleter != null) {
      if (!_completeCompleter!.isCompleted) {
        if (canceled) {
          _completeCompleter!.completeError(
            Exception('Animation canceled'),
            StackTrace.current,
          );
        } else {
          _completeCompleter!.complete();
        }
      }
      _completeCompleter = null;
    }
  }

  /// Resets the animation to [lowerBound].
  void reset() {
    value = lowerBound;
  }

  /// Releases resources. The controller must not be used after disposal.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stop();
    clearListeners();
    clearStatusListeners();
    super.dispose();
  }

  // ===========================================================================
  // Future Support (TickerFuture alternative)
  // ===========================================================================

  /// A [Future] that completes when the current animation finishes.
  ///
  /// **Note:** Each time a new animation is started (via [forward], [reverse],
  /// [animateTo], or [repeat]), a new completer is created. If you call
  /// [completed] before starting an animation, the returned Future corresponds
  /// to the previous animation (if any) and will be completed with an error if
  /// a new animation is started before the previous one completes.
  ///
  /// To wait for a specific animation, call [completed] *after* starting it.
  ///
  /// If the animation is not running, returns an already completed Future.
  Future<void> get completed {
    if (!_isAnimating) {
      return Future.value();
    }
    _completeCompleter ??= Completer<void>();
    return _completeCompleter!.future;
  }

  // ===========================================================================
  // Internal State
  // ===========================================================================

  double _value = 0.0;
  AnimationStatus _status = AnimationStatus.dismissed;
  Timer? _timer;
  bool _isAnimating = false;
  bool _disposed = false;
  int _targetFps;
  _AnimationDirection _direction = _AnimationDirection.forward;
  Completer<void>? _completeCompleter;

  // animateTo state
  double _startValue = 0.0;
  double _targetValue = 1.0;
  Curve _curve = Curves.linear;
  Duration? _animateDuration;
  DateTime? _startTime;
  Duration _elapsedAtLastStart = Duration.zero;

  // repeat state
  double? _repeatMin;
  double? _repeatMax;
  bool _repeatReverse = false;
  Duration? _repeatPeriod;
  int? _repeatCount;

  AnimationStatus _lastReportedStatus = AnimationStatus.dismissed;

  // ===========================================================================
  // Internal Implementation
  // ===========================================================================

  void _internalSetValue(double newValue) {
    _value = newValue.clamp(lowerBound, upperBound);
    if (_value == lowerBound) {
      _status = AnimationStatus.dismissed;
    } else if (_value == upperBound) {
      _status = AnimationStatus.completed;
    } else {
      _status = _direction == _AnimationDirection.forward
          ? AnimationStatus.forward
          : AnimationStatus.reverse;
    }
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError('A $runtimeType was used after being disposed.\n'
          'Once you have called dispose() on a $runtimeType, it can no longer be used.');
    }
  }

  void _animateToInternal(
    double target, {
    Duration? duration,
    Curve curve = Curves.linear,
  }) {
    final simulationDuration = duration ?? this.duration;
    assert(
      simulationDuration != null,
      'duration must be set before starting animation',
    );

    stop();
    _startValue = _value;
    _targetValue = target;
    _curve = curve;
    _animateDuration = simulationDuration;
    _startTime = DateTime.now();
    _elapsedAtLastStart = Duration.zero;
    _isAnimating = true;
    _completeCompleter = Completer<void>();

    _timer = Timer.periodic(_tickInterval, _onAnimateTick);
  }

  Duration get _tickInterval {
    return Duration(microseconds: (1000000 / _targetFps).round());
  }

  void _onAnimateTick(Timer timer) {
    if (_disposed || _timer == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(_startTime!) + _elapsedAtLastStart;
    final totalMs = _animateDuration!.inMilliseconds;
    final elapsedMs = elapsed.inMilliseconds;

    if (totalMs <= 0) {
      _internalSetValue(_targetValue);
      notifyListeners();
      _checkStatusChanged();
      _completeAnimation();
      return;
    }

    var t = elapsedMs / totalMs;

    // Defensive: t should not exceed 1.0, but use >= for safety
    if (t >= 1.0) {
      // Animation complete
      t = 1.0;
      _internalSetValue(_targetValue);
      notifyListeners();
      _checkStatusChanged();
      _completeAnimation();
      return;
    }

    // Apply curve and compute interpolated value
    final curvedT = _curve.transform(t);
    _value = _startValue + (_targetValue - _startValue) * curvedT;
    _internalSetValue(_value);
    notifyListeners();
    _checkStatusChanged();
  }

  void _onRepeatTick(Timer timer) {
    if (_disposed || _timer == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(_startTime!) + _elapsedAtLastStart;
    final totalMs = _repeatPeriod!.inMilliseconds;
    final elapsedMs = elapsed.inMilliseconds;

    if (totalMs <= 0) {
      _internalSetValue(_repeatMax!);
      notifyListeners();
      _checkStatusChanged();
      _completeAnimation();
      return;
    }

    // Compute how many full cycles have elapsed
    // Use modulo to keep cycles within a reasonable range for performance
    final cycles = elapsedMs ~/ totalMs;
    final t = (elapsedMs % totalMs) / totalMs;

    // Check if we've reached the repeat count limit
    // cycles == 0 means we're in the first cycle
    if (_repeatCount != null && cycles >= _repeatCount!) {
      // Finalize at the end position of the last cycle
      final lastCycleIndex = _repeatCount! - 1;
      final isReversePhase = _repeatReverse && lastCycleIndex.isOdd;
      _value = isReversePhase ? _repeatMin! : _repeatMax!;
      _internalSetValue(_value);
      notifyListeners();
      _checkStatusChanged();
      _completeAnimation();
      return;
    }

    // Determine current direction and progress
    final isReversePhase = _repeatReverse && cycles.isOdd;
    double progress;

    if (isReversePhase) {
      progress = 1.0 - t;
      _direction = _AnimationDirection.reverse;
    } else {
      progress = t;
      _direction = _AnimationDirection.forward;
    }

    _value = _repeatMin! + (_repeatMax! - _repeatMin!) * progress;
    _internalSetValue(_value);
    notifyListeners();
    _checkStatusChanged();
  }

  void _startTimer(Duration period, void Function(Timer) callback) {
    _assertNotDisposed();
    _timer?.cancel();
    // Complete any pending completer before starting new animation
    if (_completeCompleter != null && !_completeCompleter!.isCompleted) {
      try {
        _completeCompleter!.completeError(
          Exception('Animation was restarted before completing'),
          StackTrace.current,
        );
      } catch (e) {
        // Ignore if already completed
      }
    }
    _completeCompleter = null;
    _startTime = DateTime.now();
    _elapsedAtLastStart = Duration.zero;
    _isAnimating = true;
    _completeCompleter = Completer<void>();
    _timer = Timer.periodic(_tickInterval, callback);
  }

  void _completeAnimation() {
    _timer?.cancel();
    _timer = null;
    _isAnimating = false;

    if (_completeCompleter != null && !_completeCompleter!.isCompleted) {
      _completeCompleter!.complete();
      _completeCompleter = null;
    }
  }

  void _checkStatusChanged() {
    final newStatus = status;
    if (_lastReportedStatus != newStatus) {
      _lastReportedStatus = newStatus;
      notifyStatusListeners(newStatus);
    }
  }

  // ===========================================================================
  // Diagnostics
  // ===========================================================================

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('LottieController(');
    if (debugLabel != null) buffer.write('"$debugLabel", ');
    buffer.write('value: ${_value.toStringAsFixed(6)}, ');
    buffer.write('status: $_status, ');
    buffer.write('isAnimating: $_isAnimating, ');
    buffer.write('targetFps: $targetFps)');
    return buffer.toString();
  }
}

enum _AnimationDirection { forward, reverse }
