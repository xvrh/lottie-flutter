import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../lottie.dart';
import 'composition.dart';
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
  })  : animate = animate ?? true,
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
  }) =>
      LottieBuilder.asset(
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
  }) =>
      LottieBuilder.file(
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
  }) =>
      LottieBuilder.memory(
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
  }) =>
      LottieBuilder.network(
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

class _LottieState extends State<Lottie> with TickerProviderStateMixin {
  late AnimationController _autoAnimation;

  @override
  void initState() {
    super.initState();

    _autoAnimation = AnimationController(
        vsync: this,
        duration: widget.composition?.duration ?? const Duration(seconds: 1));
    _updateAutoAnimation();
  }

  @override
  void didUpdateWidget(Lottie oldWidget) {
    super.didUpdateWidget(oldWidget);

    _autoAnimation.duration =
        widget.composition?.duration ?? const Duration(seconds: 1);
    _updateAutoAnimation();
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

  @override
  void dispose() {
    _autoAnimation.dispose();
    super.dispose();
  }

  Animation<double> get _progressAnimation =>
      widget.controller ?? _autoAnimation;

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, _) {
        return RawLottie(
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
      },
    );

    if (widget.addRepaintBoundary) {
      child = RepaintBoundary(child: child);
    }

    return child;
  }
}
