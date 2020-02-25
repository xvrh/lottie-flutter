import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../lottie.dart';
import 'lottie_builder.dart';
import 'providers/load_image.dart';

/// A widget to display a loaded [LottieComposition].
/// The [controller] property allows to specify a custom AnimationController that
/// will drive the animation. If [controller] is null, the animation will play
/// automatically and the behavior could be adjusted with the properties [animate],
/// [repeat] and [reverse].
class Lottie extends StatefulWidget {
  Lottie({
    Key key,
    @required this.composition,
    this.controller,
    this.width,
    this.height,
    this.alignment,
    this.fit,
    bool animate,
    bool repeat,
    bool reverse,
    this.textTransform,
    this.textStyleFactory,
    this.valueDelegates,
  })  : animate = animate ?? true,
        reverse = reverse ?? false,
        repeat = repeat ?? true,
        super(key: key);

  /// Creates a widget that displays an [LottieComposition] obtained from an [AssetBundle].
  static LottieBuilder asset(String name,
          {Animation<double> controller,
          bool animate,
          bool repeat,
          bool reverse,
          void Function(LottieComposition) onLoaded,
          LottieImageProviderFactory imageProviderFactory,
          Key key,
          AssetBundle bundle,
          LottieFrameBuilder frameBuilder,
          double width,
          double height,
          BoxFit fit,
          Alignment alignment,
          String package}) =>
      LottieBuilder.asset(
        name,
        controller: controller,
        animate: animate,
        repeat: repeat,
        reverse: reverse,
        imageProviderFactory: imageProviderFactory,
        onLoaded: onLoaded,
        key: key,
        bundle: bundle,
        frameBuilder: frameBuilder,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        package: package,
      );

  /// Creates a widget that displays an [LottieComposition] obtained from a [File].
  static LottieBuilder file(
    File file, {
    Animation<double> controller,
    bool animate,
    bool repeat,
    bool reverse,
    LottieImageProviderFactory imageProviderFactory,
    void Function(LottieComposition) onLoaded,
    Key key,
    LottieFrameBuilder frameBuilder,
    double width,
    double height,
    BoxFit fit,
    Alignment alignment,
  }) =>
      LottieBuilder.file(
        file,
        controller: controller,
        animate: animate,
        repeat: repeat,
        reverse: reverse,
        imageProviderFactory: imageProviderFactory,
        onLoaded: onLoaded,
        key: key,
        frameBuilder: frameBuilder,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
      );

  /// Creates a widget that displays an [LottieComposition] obtained from a [Uint8List].
  static LottieBuilder memory(
    Uint8List bytes, {
    Animation<double> controller,
    bool animate,
    bool repeat,
    bool reverse,
    LottieImageProviderFactory imageProviderFactory,
    void Function(LottieComposition) onLoaded,
    Key key,
    LottieFrameBuilder frameBuilder,
    double width,
    double height,
    BoxFit fit,
    Alignment alignment,
  }) =>
      LottieBuilder.memory(
        bytes,
        controller: controller,
        animate: animate,
        repeat: repeat,
        reverse: reverse,
        imageProviderFactory: imageProviderFactory,
        onLoaded: onLoaded,
        key: key,
        frameBuilder: frameBuilder,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
      );

  /// Creates a widget that displays an [LottieComposition] obtained from the network.
  static LottieBuilder network(
    String url, {
    Animation<double> controller,
    bool animate,
    bool repeat,
    bool reverse,
    LottieImageProviderFactory imageProviderFactory,
    void Function(LottieComposition) onLoaded,
    Key key,
    LottieFrameBuilder frameBuilder,
    double width,
    double height,
    BoxFit fit,
    Alignment alignment,
  }) =>
      LottieBuilder.network(
        url,
        controller: controller,
        animate: animate,
        repeat: repeat,
        reverse: reverse,
        imageProviderFactory: imageProviderFactory,
        onLoaded: onLoaded,
        key: key,
        frameBuilder: frameBuilder,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
      );

  /// The Lottie composition to animate.
  /// It could be parsed asynchronously with `LottieComposition.fromBytes`.
  final LottieComposition composition;

  /// The animation controller to animate the Lottie animation.
  /// If null, a controller is automatically created by this class and is configured
  /// with the properties [animate], [reverse]
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

  /// If non-null, requires the composition to have this width.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double width;

  /// If non-null, require the composition to have this height.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double height;

  /// How to inscribe the Lottie composition into the space allocated during layout.
  final BoxFit fit;

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
  final AlignmentGeometry alignment;

  /// A list of value delegates to dynamically modify the animation
  /// properties at runtime.
  ///
  /// Example:
  /// ```dart
  /// Lottie.asset(
  ///   'lottiefile.json',
  ///   valueDelegates: [
  ///     ValueDelegate.color(['lake', 'fill'], value: Colors.blue),
  ///     ValueDelegate.opacity(['**', 'fill'], callback: (frameInfo) => 0.5 * frameInfo.overallProgress),
  /// ]);
  /// ```
  final List<ValueDelegate> valueDelegates;

  /// A callback to dynamically changes the text displayed in the lottie
  /// animation.
  /// For instance, this is useful when you want to translate the text in the animation.
  final String Function(String) textTransform;

  /// A callback to map between a font family specified in the json animation
  /// with the font family in your assets.
  /// This is useful either if:
  ///  - the name of the font in your asset doesn't match the one in the json file.
  ///  - you want to use an other font than the one declared in the json
  ///
  /// If the callback is null, the font family from the json is used as it.
  ///
  /// Given an object containing the font family and style specified in the json
  /// return a configured `TextStyle` that will be used as the base style when
  /// painting the text.
  final TextStyle Function(LottieFontStyle) textStyleFactory;

  /// Some options to customize the lottie animation.
  /// - text transform to dynamically change some text displayed in the animation
  /// - value callback to change the properties of the animation at runtime.
  /// - text style factory to map between a font family specified in the animation
  ///   and the font family in your assets.
  final LottieModifiers modifiers;

  @override
  _LottieState createState() => _LottieState();
}

class _LottieState extends State<Lottie> with TickerProviderStateMixin {
  AnimationController _autoAnimation;

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
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, _) => RawLottie(
        composition: widget.composition,
        options: widget.options,
        progress: _progressAnimation.value,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
      ),
    );
  }
}
