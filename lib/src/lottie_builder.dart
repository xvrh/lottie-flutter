import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../lottie.dart';
import 'lottie.dart';
import 'providers/asset_provider.dart';
import 'providers/file_provider.dart';
import 'providers/load_image.dart';
import 'providers/lottie_provider.dart';
import 'providers/memory_provider.dart';
import 'providers/network_provider.dart';

typedef LottieFrameBuilder = Widget Function(
  BuildContext context,
  Widget child,
  LottieComposition composition,
);

/// A widget that displays a Lottie animation.
///
/// Several constructors are provided for the various ways that a Lottie file
/// can be provided:
///
///  * [new Lottie], for obtaining a composition from a [LottieProvider].
///  * [new Lottie.asset], for obtaining a Lottie file from an [AssetBundle]
///    using a key.
///  * [new Lottie.network], for obtaining a lottie file from a URL.
///  * [new Lottie.file], for obtaining a lottie file from a [File].
///  * [new Lottie.memory], for obtaining a lottie file from a [Uint8List].
///
class LottieBuilder extends StatefulWidget {
  const LottieBuilder({
    Key key,
    @required this.lottie,
    this.controller,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    this.onLoaded,
    this.frameBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
  })  : assert(lottie != null),
        super(key: key);

  /// Creates a widget that displays an [LottieComposition] obtained from the network.
  LottieBuilder.network(
    String src, {
    Map<String, String> headers,
    this.controller,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    LottieImageProviderFactory imageProviderFactory,
    this.onLoaded,
    Key key,
    this.frameBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
  })  : lottie = NetworkLottie(src,
            headers: headers, imageProviderFactory: imageProviderFactory),
        super(key: key);

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
    File file, {
    this.controller,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    LottieImageProviderFactory imageProviderFactory,
    this.onLoaded,
    Key key,
    this.frameBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
  })  : lottie = FileLottie(file, imageProviderFactory: imageProviderFactory),
        super(key: key);

  /// Creates a widget that displays an [LottieComposition] obtained from an [AssetBundle].
  LottieBuilder.asset(
    String name, {
    this.controller,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    LottieImageProviderFactory imageProviderFactory,
    this.onLoaded,
    Key key,
    AssetBundle bundle,
    this.frameBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    String package,
  })  : lottie = AssetLottie(name,
            bundle: bundle,
            package: package,
            imageProviderFactory: imageProviderFactory),
        super(key: key);

  /// Creates a widget that displays an [LottieComposition] obtained from a [Uint8List].
  LottieBuilder.memory(
    Uint8List bytes, {
    this.controller,
    this.animate,
    this.reverse,
    this.repeat,
    this.delegates,
    this.options,
    LottieImageProviderFactory imageProviderFactory,
    this.onLoaded,
    Key key,
    this.frameBuilder,
    this.width,
    this.height,
    this.fit,
    this.alignment,
  })  : lottie =
            MemoryLottie(bytes, imageProviderFactory: imageProviderFactory),
        super(key: key);

  /// The lottie animation to load.
  /// Example of providers: [AssetLottie], [NetworkLottie], [FileLottie], [MemoryLottie]
  final LottieProvider lottie;

  /// A callback called when the LottieComposition has been loaded.
  /// You can use this callback to set the correct duration on the AnimationController
  /// with `composition.duration`
  final void Function(LottieComposition) onLoaded;

  /// The animation controller of the Lottie animation.
  /// The animated value will be mapped to the `progress` property of the
  /// Lottie animation.
  final Animation<double> controller;

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

  /// A group of options to further customize the lottie animation.
  /// - A [text] delegate to dynamically change some text displayed in the animation
  /// - A value callback to change the properties of the animation at runtime.
  /// - A text style factory to map between a font family specified in the animation
  ///   and the font family in your assets.
  final LottieDelegates delegates;

  /// Some options to enable/disable some feature of Lottie
  /// - enableMergePaths: Enable merge path support
  final LottieOptions options;

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
  final LottieFrameBuilder frameBuilder;

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
  final double width;

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
  final double height;

  /// How to inscribe the animation into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

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
  final AlignmentGeometry alignment;

  @override
  _LottieBuilderState createState() => _LottieBuilderState();

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
  Future<LottieComposition> _loadingFuture;

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void didUpdateWidget(LottieBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lottie != widget.lottie) {
      _load();
    }
  }

  void _load() {
    var provider = widget.lottie;
    _loadingFuture = widget.lottie.load().then((composition) {
      if (mounted && widget.onLoaded != null && widget.lottie == provider) {
        widget.onLoaded(composition);
      }

      return composition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (kDebugMode) {
            return ErrorWidget(snapshot.error);
          }
        }

        var composition = snapshot.data;

        Widget result = Lottie(
          composition: composition,
          controller: widget.controller,
          animate: widget.animate,
          reverse: widget.reverse,
          repeat: widget.repeat,
          delegates: widget.delegates,
          options: widget.options,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
        );

        if (widget.frameBuilder != null) {
          result = widget.frameBuilder(context, result, composition);
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
