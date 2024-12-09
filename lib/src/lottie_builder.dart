import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'composition.dart';
import 'frame_rate.dart';
import 'lottie.dart';
import 'lottie_delegates.dart';
import 'options.dart';
import 'providers/asset_provider.dart';
import 'providers/file_provider.dart';
import 'providers/load_image.dart';
import 'providers/lottie_provider.dart';
import 'providers/memory_provider.dart';
import 'providers/network_provider.dart';
import 'render_cache.dart';

typedef LottieFrameBuilder = Widget Function(
  BuildContext context,
  Widget child,
  LottieComposition? composition,
);

/// Signature used by [Lottie.errorBuilder] to create a replacement widget to
/// render instead of the image.
typedef LottieErrorWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// A widget that displays a Lottie animation.
///
/// Several constructors are provided for the various ways that a Lottie file
/// can be provided:
///
///  * [Lottie], for obtaining a composition from a [LottieProvider].
///  * [Lottie.asset], for obtaining a Lottie file from an [AssetBundle]
///    using a key.
///  * [Lottie.network], for obtaining a lottie file from a URL.
///  * [Lottie.file], for obtaining a lottie file from a [File].
///  * [Lottie.memory], for obtaining a lottie file from a [Uint8List].
///
class LottieBuilder extends StatefulWidget {
  const LottieBuilder({
    super.key,
    required this.lottie,
    this.controller,
    this.frameRate,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    this.onLoaded,
    this.frameBuilder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.addRepaintBoundary,
    this.filterQuality,
    this.onWarning,
    this.renderCache,
  });

  /// Creates a widget that displays an [LottieComposition] obtained from the network.
  LottieBuilder.network(
    String src, {
    http.Client? client,
    Map<String, String>? headers,
    this.controller,
    this.frameRate,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    LottieImageProviderFactory? imageProviderFactory,
    this.onLoaded,
    super.key,
    this.frameBuilder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.addRepaintBoundary,
    this.filterQuality,
    this.onWarning,
    LottieDecoder? decoder,
    this.renderCache,
    bool? backgroundLoading,
  }) : lottie = NetworkLottie(src,
            client: client,
            headers: headers,
            imageProviderFactory: imageProviderFactory,
            decoder: decoder,
            backgroundLoading: backgroundLoading);

  /// Creates a widget that displays an [LottieComposition] obtained from a [File].
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the animation is loaded, which
  /// will result in ugly layout changes.
  ///
  /// On Android, this may require the
  /// `android.permission.READ_EXTERNAL_STORAGE` permission.
  ///
  LottieBuilder.file(
    Object file, {
    this.controller,
    this.frameRate,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    LottieImageProviderFactory? imageProviderFactory,
    this.onLoaded,
    super.key,
    this.frameBuilder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.addRepaintBoundary,
    this.filterQuality,
    this.onWarning,
    LottieDecoder? decoder,
    this.renderCache,
    bool? backgroundLoading,
  }) : lottie = FileLottie(
          file,
          imageProviderFactory: imageProviderFactory,
          decoder: decoder,
          backgroundLoading: backgroundLoading,
        );

  /// Creates a widget that displays an [LottieComposition] obtained from an [AssetBundle].
  LottieBuilder.asset(
    String name, {
    this.controller,
    this.frameRate,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    LottieImageProviderFactory? imageProviderFactory,
    this.onLoaded,
    super.key,
    AssetBundle? bundle,
    this.frameBuilder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    String? package,
    this.addRepaintBoundary,
    this.filterQuality,
    this.onWarning,
    LottieDecoder? decoder,
    this.renderCache,
    bool? backgroundLoading,
  }) : lottie = AssetLottie(name,
            bundle: bundle,
            package: package,
            imageProviderFactory: imageProviderFactory,
            decoder: decoder,
            backgroundLoading: backgroundLoading);

  /// Creates a widget that displays an [LottieComposition] obtained from a [Uint8List].
  LottieBuilder.memory(
    Uint8List bytes, {
    this.controller,
    this.frameRate,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    LottieImageProviderFactory? imageProviderFactory,
    this.onLoaded,
    this.errorBuilder,
    super.key,
    this.frameBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.addRepaintBoundary,
    this.filterQuality,
    this.onWarning,
    LottieDecoder? decoder,
    this.renderCache,
    bool? backgroundLoading,
  }) : lottie = MemoryLottie(
          bytes,
          imageProviderFactory: imageProviderFactory,
          decoder: decoder,
          backgroundLoading: backgroundLoading,
        );

  /// The lottie animation to load.
  /// Example of providers: [AssetLottie], [NetworkLottie], [FileLottie], [MemoryLottie]
  final LottieProvider lottie;

  /// A callback called when the LottieComposition has been loaded.
  /// You can use this callback to set the correct duration on the AnimationController
  /// with `composition.duration`
  final void Function(LottieComposition)? onLoaded;

  /// The animation controller of the Lottie animation.
  /// The animated value will be mapped to the `progress` property of the
  /// Lottie animation.
  final Animation<double>? controller;

  /// The number of frames per second to render.
  /// Use `FrameRate.composition` to use the original frame rate of the Lottie composition (default)
  /// Use `FrameRate.max` to advance the animation progression at every frame.
  final FrameRate? frameRate;

  /// If no controller is specified, this value indicate whether or not the
  /// Lottie animation should be played automatically (default to true).
  /// If there is an animation controller specified, this property has no effect.
  ///
  /// See [repeat] to control whether the animation should repeat.
  final bool? animate;

  /// Specify that the automatic animation should repeat in a loop (default to true).
  /// The property has no effect if [animate] is false or [controller] is not null.
  final bool? repeat;

  /// Specify that the automatic animation should repeat in a loop in a "reverse"
  /// mode (go from start to end and then continuously from end to start).
  /// It default to false.
  /// The property has no effect if [animate] is false, [repeat] is false or [controller] is not null.
  final bool? reverse;

  /// A group of options to further customize the lottie animation.
  /// - A [text] delegate to dynamically change some text displayed in the animation
  /// - A value callback to change the properties of the animation at runtime.
  /// - A text style factory to map between a font family specified in the animation
  ///   and the font family in your assets.
  final LottieDelegates? delegates;

  /// Some options to enable/disable some feature of Lottie
  /// - enableMergePaths: Enable merge path support
  /// - enableApplyingOpacityToLayers: Enable layer-level opacity
  final LottieOptions? options;

  /// A builder function responsible for creating the widget that represents
  /// this lottie animation.
  ///
  /// If this is null, this widget will display a lottie animation that is painted as
  /// soon as it is available (and will appear to "pop" in
  /// if it becomes available asynchronously). Callers might use this builder to
  /// add effects to the animation (such as fading the animation in when it becomes
  /// available) or to display a placeholder widget while the animation is loading.
  ///
  /// To have finer-grained control over the way that an animation's loading
  /// progress is communicated to the user, see [loadingBuilder].
  ///
  /// {@template lottie.chainedBuildersExample}
  /// ```dart
  /// Lottie(
  ///   ...
  ///   frameBuilder: (BuildContext context, Widget child) {
  ///     return Padding(
  ///       padding: EdgeInsets.all(8.0),
  ///       child: child,
  ///     );
  ///   }
  /// )
  /// ```
  ///
  /// In this example, the widget hierarchy will contain the following:
  ///
  /// ```dart
  /// Center(
  ///   Padding(
  ///     padding: EdgeInsets.all(8.0),
  ///     child: <lottie>,
  ///   ),
  /// )
  /// ```
  /// {@endtemplate}
  ///
  /// {@tool snippet --template=stateless_widget_material}
  ///
  /// The following sample demonstrates how to use this builder to implement an
  /// animation that fades in once it's been loaded.
  ///
  /// This sample contains a limited subset of the functionality that the
  /// [FadeInImage] widget provides out of the box.
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return DecoratedBox(
  ///     decoration: BoxDecoration(
  ///       color: Colors.white,
  ///       border: Border.all(),
  ///       borderRadius: BorderRadius.circular(20),
  ///     ),
  ///     child: Lottie.network(
  ///       'https://example.com/animation.json',
  ///       frameBuilder: (BuildContext context, Widget child) {
  ///         if (wasSynchronouslyLoaded) {
  ///           return child;
  ///         }
  ///         return AnimatedOpacity(
  ///           child: child,
  ///           opacity: frame == null ? 0 : 1,
  ///           duration: const Duration(seconds: 1),
  ///           curve: Curves.easeOut,
  ///         );
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  final LottieFrameBuilder? frameBuilder;

  /// If non-null, require the lottie animation to have this width.
  ///
  /// If null, the lottie animation will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the animation does not change size as it loads.
  /// Consider using [fit] to adapt the animation's rendering to fit the given width
  /// and height if the exact animation dimensions are not known in advance.
  final double? width;

  /// If non-null, require the lottie animation to have this height.
  ///
  /// If null, the lottie animation will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the animation does not change size as it loads.
  /// Consider using [fit] to adapt the animation's rendering to fit the given width
  /// and height if the exact animation dimensions are not known in advance.
  final double? height;

  /// How to inscribe the animation into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// How to align the animation within its bounds.
  ///
  /// The alignment aligns the given position in the animation to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the animation to the top-left corner of its layout bounds, while an
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// animation with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the animation with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// To display a subpart of an animation, consider using a [CustomPainter] and
  /// [Canvas.drawImageRect].
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
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

  /// Indicate to automatically add a `RepaintBoundary` widget around the animation.
  /// This allows to optimize the app performance by isolating the animation in its
  /// own `Layer`.
  ///
  /// This property is `true` by default.
  final bool? addRepaintBoundary;

  /// The quality of the image layer. See [FilterQuality]
  /// [FilterQuality.high] is highest quality but slowest.
  ///
  /// Defaults to [FilterQuality.low]
  final FilterQuality? filterQuality;

  /// A callback called when there is a warning during the loading or painting
  /// of the animation.
  final WarningCallback? onWarning;

  /// A builder function that is called if an error occurs during loading.
  ///
  /// If this builder is not provided, any exceptions will be reported to
  /// [FlutterError.onError]. If it is provided, the caller should either handle
  /// the exception by providing a replacement widget, or rethrow the exception.
  ///
  /// The following sample uses [errorBuilder] to show a '😢' in place of the
  /// image that fails to load, and prints the error to the console.
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return DecoratedBox(
  ///     decoration: BoxDecoration(
  ///       color: Colors.white,
  ///     ),
  ///     child: Lottie.network(
  ///       'https://example.does.not.exist/lottie.json',
  ///       errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
  ///         // Appropriate logging or analytics, e.g.
  ///         // myAnalytics.recordError(
  ///         //   'An error occurred loading "https://example.does.not.exist/animation.json"',
  ///         //   exception,
  ///         //   stackTrace,
  ///         // );
  ///         return const Text('😢');
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  final ImageErrorWidgetBuilder? errorBuilder;

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
  final RenderCache? renderCache;

  @override
  State<LottieBuilder> createState() => _LottieBuilderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LottieProvider>('lottie', lottie));
    properties.add(DiagnosticsProperty<Function>('frameBuilder', frameBuilder));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        defaultValue: null));
  }
}

class _LottieBuilderState extends State<LottieBuilder> {
  Future<LottieComposition>? _loadingFuture;

  @override
  void didUpdateWidget(LottieBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lottie != widget.lottie) {
      _load();
    }
  }

  void _load() {
    var provider = widget.lottie;
    _loadingFuture = widget.lottie.load(context: context).then((composition) {
      // LottieProvider.load() can return a Synchronous future and the onLoaded
      // callback can call setState, so we wrap it in a microtask to avoid an
      // "!_isDirty" error.
      scheduleMicrotask(() {
        if (mounted && widget.lottie == provider) {
          var onWarning = widget.onWarning;
          composition.onWarning = onWarning;
          if (onWarning != null) {
            for (var warning in composition.warnings) {
              onWarning(warning);
            }
          }

          widget.onLoaded?.call(composition);
        }
      });

      return composition;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We need to wait the first build instead of initState because AssetLottie
    // provider may call DefaultAssetBundle.of
    if (_loadingFuture == null) {
      _load();
    }
    return FutureBuilder<LottieComposition>(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          var errorBuilder = widget.errorBuilder;
          if (errorBuilder != null) {
            return errorBuilder(context, snapshot.error!, snapshot.stackTrace);
          } else if (kDebugMode) {
            return SizedBox(
              width: widget.width,
              height: widget.height,
              child: ErrorWidget(snapshot.error!),
            );
          }
        }

        var composition = snapshot.data;
        var animate = widget.animate;
        animate ??= (composition?.durationFrames ?? 0) > 1.0;

        Widget result = Lottie(
          composition: composition,
          controller: widget.controller,
          frameRate: widget.frameRate,
          animate: animate,
          reverse: widget.reverse,
          repeat: widget.repeat,
          delegates: widget.delegates,
          options: widget.options,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          addRepaintBoundary: widget.addRepaintBoundary,
          filterQuality: widget.filterQuality,
          renderCache: widget.renderCache,
        );

        if (widget.frameBuilder != null) {
          result = widget.frameBuilder!(context, result, composition);
        }

        return result;
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<Future<LottieComposition>>(
        'loadingFuture', _loadingFuture));
  }
}
