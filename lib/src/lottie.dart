import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../lottie.dart';
import 'composition.dart';
import 'detect_flutter_test.dart';
import 'l.dart';
import 'lottie_builder.dart';
import 'providers/lottie_provider.dart';

/// A widget to display a loaded [LottieComposition].
/// The [controller] property allows to specify a custom AnimationController that
/// will drive the animation. If [controller] is null, the animation will play
/// automatically and the behavior could be adjusted with the properties [animate],
/// [repeat] and [reverse].
class Lottie extends StatefulWidget {
  /// The cache instance for recently loaded Lottie compositions.
  static LottieCache get cache => sharedLottieCache;

  const Lottie({
    super.key,
    required this.composition,
    this.controller,
    this.width,
    this.height,
    this.alignment,
    this.fit,
    bool? animate,
    this.frameRate,
    bool? repeat,
    bool? reverse,
    this.delegates,
    this.options,
    bool? addRepaintBoundary,
    this.filterQuality,
    this.renderCache,
  }) : animate = animate ?? true,
       reverse = reverse ?? false,
       repeat = repeat ?? true,
       addRepaintBoundary = addRepaintBoundary ?? true;

  /// Creates a widget that displays an [LottieComposition] obtained from an [AssetBundle].
  static LottieBuilder asset(
    String name, {
    Animation<double>? controller,
    bool? animate,
    FrameRate? frameRate,
    bool? repeat,
    bool? reverse,
    LottieDelegates? delegates,
    LottieOptions? options,
    void Function(LottieComposition)? onLoaded,
    LottieImageProviderFactory? imageProviderFactory,
    Key? key,
    AssetBundle? bundle,
    LottieFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    String? package,
    bool? addRepaintBoundary,
    FilterQuality? filterQuality,
    WarningCallback? onWarning,
    LottieDecoder? decoder,
    RenderCache? renderCache,
    bool? backgroundLoading,
  }) => LottieBuilder.asset(
    name,
    controller: controller,
    frameRate: frameRate,
    animate: animate,
    repeat: repeat,
    reverse: reverse,
    delegates: delegates,
    options: options,
    imageProviderFactory: imageProviderFactory,
    onLoaded: onLoaded,
    key: key,
    bundle: bundle,
    frameBuilder: frameBuilder,
    errorBuilder: errorBuilder,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    package: package,
    addRepaintBoundary: addRepaintBoundary,
    filterQuality: filterQuality,
    onWarning: onWarning,
    decoder: decoder,
    renderCache: renderCache,
    backgroundLoading: backgroundLoading,
  );

  /// Creates a widget that displays an [LottieComposition] obtained from a [File].
  static LottieBuilder file(
    Object file, {
    Animation<double>? controller,
    FrameRate? frameRate,
    bool? animate,
    bool? repeat,
    bool? reverse,
    LottieDelegates? delegates,
    LottieOptions? options,
    LottieImageProviderFactory? imageProviderFactory,
    void Function(LottieComposition)? onLoaded,
    Key? key,
    LottieFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    bool? addRepaintBoundary,
    FilterQuality? filterQuality,
    WarningCallback? onWarning,
    LottieDecoder? decoder,
    RenderCache? renderCache,
    bool? backgroundLoading,
  }) => LottieBuilder.file(
    file,
    controller: controller,
    frameRate: frameRate,
    animate: animate,
    repeat: repeat,
    reverse: reverse,
    delegates: delegates,
    options: options,
    imageProviderFactory: imageProviderFactory,
    onLoaded: onLoaded,
    key: key,
    frameBuilder: frameBuilder,
    errorBuilder: errorBuilder,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    addRepaintBoundary: addRepaintBoundary,
    filterQuality: filterQuality,
    onWarning: onWarning,
    decoder: decoder,
    renderCache: renderCache,
    backgroundLoading: backgroundLoading,
  );

  /// Creates a widget that displays an [LottieComposition] obtained from a [Uint8List].
  static LottieBuilder memory(
    Uint8List bytes, {
    Animation<double>? controller,
    FrameRate? frameRate,
    bool? animate,
    bool? repeat,
    bool? reverse,
    LottieDelegates? delegates,
    LottieOptions? options,
    LottieImageProviderFactory? imageProviderFactory,
    void Function(LottieComposition)? onLoaded,
    Key? key,
    LottieFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    bool? addRepaintBoundary,
    FilterQuality? filterQuality,
    WarningCallback? onWarning,
    LottieDecoder? decoder,
    RenderCache? renderCache,
    bool? backgroundLoading,
  }) => LottieBuilder.memory(
    bytes,
    controller: controller,
    frameRate: frameRate,
    animate: animate,
    repeat: repeat,
    reverse: reverse,
    delegates: delegates,
    options: options,
    imageProviderFactory: imageProviderFactory,
    onLoaded: onLoaded,
    key: key,
    frameBuilder: frameBuilder,
    errorBuilder: errorBuilder,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    addRepaintBoundary: addRepaintBoundary,
    filterQuality: filterQuality,
    onWarning: onWarning,
    decoder: decoder,
    renderCache: renderCache,
    backgroundLoading: backgroundLoading,
  );

  /// Creates a widget that displays an [LottieComposition] obtained from the network.
  static LottieBuilder network(
    String url, {
    http.Client? client,
    Map<String, String>? headers,
    Animation<double>? controller,
    FrameRate? frameRate,
    bool? animate,
    bool? repeat,
    bool? reverse,
    LottieDelegates? delegates,
    LottieOptions? options,
    LottieImageProviderFactory? imageProviderFactory,
    void Function(LottieComposition)? onLoaded,
    Key? key,
    LottieFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    bool? addRepaintBoundary,
    FilterQuality? filterQuality,
    WarningCallback? onWarning,
    LottieDecoder? decoder,
    RenderCache? renderCache,
    bool? backgroundLoading,
  }) => LottieBuilder.network(
    url,
    client: client,
    headers: headers,
    controller: controller,
    frameRate: frameRate,
    animate: animate,
    repeat: repeat,
    reverse: reverse,
    delegates: delegates,
    options: options,
    imageProviderFactory: imageProviderFactory,
    onLoaded: onLoaded,
    key: key,
    frameBuilder: frameBuilder,
    errorBuilder: errorBuilder,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    addRepaintBoundary: addRepaintBoundary,
    filterQuality: filterQuality,
    onWarning: onWarning,
    decoder: decoder,
    renderCache: renderCache,
    backgroundLoading: backgroundLoading,
  );

  /// The Lottie composition to animate.
  /// It could be parsed asynchronously with `LottieComposition.fromBytes`.
  final LottieComposition? composition;

  /// The animation controller to animate the Lottie animation.
  /// If null, a controller is automatically created by this class and is configured
  /// with the properties [animate], [reverse]
  final Animation<double>? controller;

  /// The number of frames per second to render.
  /// Use `FrameRate.composition` to use the original frame rate of the Lottie composition (default)
  /// Use `FrameRate.max` to advance the animation progression at every frame.
  ///
  /// The advantage of using a low frame rate is to preserve the device battery
  /// by doing less rendering work.
  final FrameRate? frameRate;

  /// If no controller is specified, this value indicate whether or not the
  /// Lottie animation should be played automatically (default to true).
  /// If there is an animation controller specified, this property has no effect.
  ///
  /// See [repeat] to control whether the animation should repeat.
  final bool animate;

  /// Specify that the automatic animation should repeat in a loop (default to true).
  /// The property has no effect if [animate] is false or [controller] is not null.
  final bool repeat;

  /// Specify that the automatic animation should repeat in a loop in a "reverse"
  /// mode (go from start to end and then continuously from end to start).
  /// It default to false.
  /// The property has no effect if [animate] is false, [repeat] is false or [controller] is not null.
  final bool reverse;

  /// If non-null, requires the composition to have this width.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double? width;

  /// If non-null, require the composition to have this height.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double? height;

  /// How to inscribe the Lottie composition into the space allocated during layout.
  final BoxFit? fit;

  /// How to align the composition within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry? alignment;

  /// A group of callbacks to further customize the lottie animation.
  /// - A [text] delegate to dynamically change some text displayed in the animation
  /// - A value callback to change the properties of the animation at runtime.
  /// - A text style factory to map between a font family specified in the animation
  ///   and the font family in your assets.
  final LottieDelegates? delegates;

  /// Some options to enable/disable some feature of Lottie
  /// - enableMergePaths: Enable merge path support
  /// - enableApplyingOpacityToLayers: Enable layer-level opacity
  final LottieOptions? options;

  /// Indicate to automatically add a `RepaintBoundary` widget around the animation.
  /// This allows to optimize the app performance by isolating the animation in its
  /// own `Layer`.
  ///
  /// This property is `true` by default.
  final bool addRepaintBoundary;

  /// The quality of the image layer. See [FilterQuality]
  /// [FilterQuality.high] is highest quality but slowest.
  ///
  /// Defaults to [FilterQuality.low]
  final FilterQuality? filterQuality;

  /// {@template lottie.renderCache}
  /// Opt-in to a special render mode where the frames of the animation are
  /// lazily rendered and kept in a cache.
  /// Subsequent runs of the animation will be cheaper to render.
  ///
  /// This is useful is the animation is complex and can consume lot of energy
  /// from the battery.
  /// This will trade an excessive CPU usage for an increase memory usage.
  /// The main use-case is a short and small (size on the screen) animation that is
  /// played repeatedly.
  ///
  /// There are 2 kinds of caches:
  /// - [RenderCache.raster]: keep the frame rasterized in the cache (as [dart:ui.Image]).
  ///   Subsequent runs of the animation are very cheap for both the CPU and GPU but it takes
  ///   a lot of memory (rendered_width * rendered_height * frame_rate * duration_of_the_animation).
  ///   This should only be used for very short and very small animations.
  /// - [RenderCache.drawingCommands]: keep the frame as a list of graphical operations ([dart:ui.Picture]).
  ///   Subsequent runs of the animation are cheaper for the CPU but not for the GPU.
  ///   Memory usage is a lot lower than RenderCache.raster.
  ///
  /// The render cache is managed internally and will release the memory once the
  /// animation disappear. The cache is shared between all animations.

  /// Any change in the configuration of the animation (delegates, frame rate etc...)
  /// will clear the cache entry.
  /// For RenderCache.raster, any change in the size will invalidate the cache entry. The cache
  /// use the final size visible on the screen (with all transforms applied).
  ///
  /// In order to not exceed the memory limit of a device, the raster cache is constrained
  /// to maximum 50MB. After that, animations are not cached anymore.
  /// {@endtemplate}
  final RenderCache? renderCache;

  static bool get traceEnabled => L.traceEnabled;
  static set traceEnabled(bool enabled) {
    L.traceEnabled = enabled;
  }

  @override
  State<Lottie> createState() => _LottieState();
}

/// Whether the auto-animation frame-rate throttle stays active inside
/// `flutter test`.
///
/// The throttle parks the animation on a [Timer] between composition frames,
/// which `tester.pumpAndSettle()` cannot observe: it would settle while the
/// animation is still mid-flight. To keep the usual test semantics, the
/// throttle is disabled under `flutter test` unless this flag is set to true
/// (as this package's own throttle tests do).
@visibleForTesting
bool debugThrottleAnimationsInTests = false;

class _LottieState extends State<Lottie> {
  final _tickerProvider = _ThrottledTickerProvider();
  ValueListenable<TickerModeData>? _tickerModeNotifier;
  late AnimationController _autoAnimation;

  /// The last frame we rebuilt for, expressed as the frame-rate-rounded
  /// progress. The vsync ticker notifies us every frame, but we only rebuild
  /// when this value actually changes, so build/paint run at the composition's
  /// frame rate instead of the display refresh rate.
  double? _renderedProgress;

  @override
  void initState() {
    super.initState();

    // Apply the ambient TickerMode before the controller starts, so that a
    // widget mounted under TickerMode(enabled: false) never requests a frame
    // (getValuesNotifier reads the inherited widget without registering a
    // dependency, so it is legal here).
    _updateTickerModeNotifier();
    _tickerProvider.interval = _tickInterval;
    _autoAnimation = AnimationController(
      vsync: _tickerProvider,
      duration: widget.composition?.duration ?? const Duration(seconds: 1),
    );
    _progressAnimation.addListener(_onProgressChanged);
    _updateAutoAnimation();
  }

  @override
  void activate() {
    super.activate();
    _updateTickerModeNotifier();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTickerModeNotifier();
    _tickerProvider.vsyncPeriod = _displayVsyncPeriod;
  }

  void _updateTickerModeNotifier() {
    var notifier = TickerMode.getValuesNotifier(context);
    if (notifier != _tickerModeNotifier) {
      _tickerModeNotifier?.removeListener(_updateTickerMode);
      _tickerModeNotifier = notifier..addListener(_updateTickerMode);
      _updateTickerMode();
    }
  }

  void _updateTickerMode() {
    var values = _tickerModeNotifier?.value;
    _tickerProvider.applyTickerMode(
      enabled: values?.enabled ?? true,
      forceFrames: values?.forceFrames ?? false,
    );
  }

  @override
  void didUpdateWidget(Lottie oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _autoAnimation).removeListener(
        _onProgressChanged,
      );
      _progressAnimation.addListener(_onProgressChanged);
    }

    _autoAnimation.duration =
        widget.composition?.duration ?? const Duration(seconds: 1);
    _tickerProvider.interval = _tickInterval;
    _updateAutoAnimation();
  }

  /// The interval between ticks of the auto-animation, derived from the target
  /// frame rate, or null to tick on every vsync ([FrameRate.max]).
  ///
  /// Inside `flutter test` the throttle is disabled by default: the ticker
  /// parks on a [Timer] between composition frames, which
  /// `tester.pumpAndSettle()` cannot observe — it would settle while the
  /// animation is still mid-flight. [debugThrottleAnimationsInTests] restores
  /// the throttle for tests that exercise it.
  Duration? get _tickInterval {
    if (isRunningInFlutterTest && !debugThrottleAnimationsInTests) return null;
    var fps = _frameRate.resolveFps(widget.composition?.frameRate);
    if (fps == null) return null;
    return Duration(
      microseconds: (Duration.microsecondsPerSecond / fps).round(),
    );
  }

  /// The estimated refresh period of the display this widget's view is on.
  Duration get _displayVsyncPeriod {
    var refreshRate = View.maybeOf(context)?.display.refreshRate;
    if (refreshRate == null || !refreshRate.isFinite || refreshRate <= 0) {
      refreshRate = 60;
    }
    return Duration(
      microseconds: (Duration.microsecondsPerSecond / refreshRate).round(),
    );
  }

  void _updateAutoAnimation() {
    _autoAnimation.stop();

    if (widget.animate && widget.controller == null) {
      if (widget.repeat) {
        _autoAnimation.repeat(reverse: widget.reverse);
      } else {
        _autoAnimation.forward();
      }
    }
  }

  /// Called on every vsync tick. Quantizes the raw progress to the target frame
  /// rate and only triggers a rebuild when the resulting frame changes.
  void _onProgressChanged() {
    var rounded =
        widget.composition?.roundProgress(
          _progressAnimation.value,
          frameRate: _frameRate,
        ) ??
        _progressAnimation.value;
    if (rounded != _renderedProgress) {
      setState(() => _renderedProgress = rounded);
    }
  }

  FrameRate get _frameRate => widget.frameRate ?? FrameRate.composition;

  @override
  void dispose() {
    _tickerModeNotifier?.removeListener(_updateTickerMode);
    _progressAnimation.removeListener(_onProgressChanged);
    _autoAnimation.dispose();
    super.dispose();
  }

  Animation<double> get _progressAnimation =>
      widget.controller ?? _autoAnimation;

  @override
  Widget build(BuildContext context) {
    Widget child = RawLottie(
      composition: widget.composition,
      delegates: widget.delegates,
      options: widget.options,
      progress: _progressAnimation.value,
      frameRate: widget.frameRate,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      filterQuality: widget.filterQuality,
      renderCache: widget.renderCache,
    );

    if (widget.addRepaintBoundary) {
      child = RepaintBoundary(child: child);
    }

    return child;
  }
}

class _ThrottledTickerProvider implements TickerProvider {
  /// Target interval between ticks; null means tick on every vsync.
  Duration? interval;

  /// Estimated refresh period of the display the widget is on.
  Duration vsyncPeriod = const Duration(microseconds: 1000000 ~/ 60);

  bool _muted = false;
  bool _forceFrames = false;
  _ThrottledTicker? _ticker;

  void applyTickerMode({required bool enabled, required bool forceFrames}) {
    _muted = !enabled;
    _forceFrames = forceFrames;
    _ticker
      ?..muted = _muted
      ..forceFrames = _forceFrames;
  }

  @override
  Ticker createTicker(TickerCallback onTick) {
    // Configuration lives on the provider so that a re-created ticker (e.g.
    // through AnimationController.resync) stays throttled and muted.
    return _ticker = _ThrottledTicker(onTick, this)
      ..muted = _muted
      ..forceFrames = _forceFrames;
  }
}

/// A [Ticker] that fires at most once per [interval] instead of on every vsync.
///
/// A regular ticker re-arms a frame callback immediately after each tick, which
/// keeps the engine pumping full frames (build, composite, raster) at the
/// display refresh rate even when nothing rebuilds. This ticker instead delays
/// re-arming with a timer, so no frame is even scheduled between two
/// composition frames and the whole pipeline runs at the composition rate.
///
/// Tick timestamps still come from the vsync that follows each timer, so the
/// animation stays wall-clock correct: a late timer or a busy frame drops
/// frames rather than slowing the animation down. Muting (TickerMode) and
/// stopping cancel the pending timer through [unscheduleTick]. In the
/// background the chain parks itself: the timer fires once, the scheduled
/// frame never arrives, and no further timer is created until vsync resumes.
class _ThrottledTicker extends Ticker {
  _ThrottledTicker(super.onTick, this._provider);

  final _ThrottledTickerProvider _provider;
  Duration? _nextTarget;
  Timer? _delayTimer;

  @override
  bool get shouldScheduleTick =>
      super.shouldScheduleTick && _delayTimer == null;

  @override
  void scheduleTick({bool rescheduling = false}) {
    var interval = _provider.interval;
    if (!rescheduling || interval == null) {
      // Initial tick after start()/unmute: fire on the next vsync.
      _nextTarget = null;
      super.scheduleTick(rescheduling: rescheduling);
      return;
    }

    // Aim for the previous target plus one interval so that vsync latency
    // doesn't accumulate; the frame timestamp is the clock the ticker itself
    // runs on (also correct under timeDilation and the fake clock in tests,
    // unlike a Stopwatch). Keep the target within one interval of the actual
    // tick time: it can fall behind (jank, resume from background) or creep
    // ahead (rounding drift between the interval and the real vsync grid) —
    // both reset to one interval from now instead of trying to catch up.
    var now = SchedulerBinding.instance.currentFrameTimeStamp;
    var target = (_nextTarget ?? now) + interval;
    if (target <= now || target > now + interval) {
      target = now + interval;
    }
    _nextTarget = target;

    // `now` is a vsync timestamp, so vsyncs land near `now + k * period`. Arm
    // the timer just after the last vsync preceding the target: timers never
    // fire early, so the frame request goes out one vsync ahead of the target
    // and the tick lands on the first vsync at or after it. Arming later
    // would slip one vsync past every target (halving compositions at the
    // display rate); arming a full vsync earlier would tick before the
    // composition-frame boundary, which the rebuild gate discards — skipping
    // frames when the rates don't divide (24fps on 60Hz).
    var period = _provider.vsyncPeriod.inMicroseconds;
    var wholePeriods = ((target - now).inMicroseconds - 1) ~/ period;
    var delay = Duration(microseconds: wholePeriods * period);
    if (delay <= Duration.zero) {
      super.scheduleTick(rescheduling: rescheduling);
      return;
    }

    _delayTimer = Timer(delay, () {
      _delayTimer = null;
      if (shouldScheduleTick) {
        super.scheduleTick();
      }
    });
  }

  @override
  void unscheduleTick() {
    _delayTimer?.cancel();
    _delayTimer = null;
    super.unscheduleTick();
  }
}
