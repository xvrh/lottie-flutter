import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../lottie.dart';
import 'lottie_builder.dart';
import 'providers/load_image.dart';

class Lottie extends StatefulWidget {
  final LottieComposition composition;

  /// The animation controller to animate the Lottie animation.
  /// If null, a controller is automatically created by this class and is configured
  /// with the properties [animate], [reverse]
  final Animation<double> controller;

  /// If no controller is specified, use this values to automatically plays the
  /// Lottie animation.
  final bool animate, reverse, repeat;
  final double width, height;
  final AlignmentGeometry alignment;
  final BoxFit fit;

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
  })  : animate = animate ?? true,
        reverse = reverse ?? false,
        repeat = repeat ?? true,
        super(key: key);

  static LottieBuilder asset(String name,
          {Animation<double> controller,
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

  static LottieBuilder file(
    File file, {
    Animation<double> controller,
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
        imageProviderFactory: imageProviderFactory,
        onLoaded: onLoaded,
        key: key,
        frameBuilder: frameBuilder,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
      );

  static LottieBuilder memory(
    Uint8List bytes, {
    Animation<double> controller,
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
        imageProviderFactory: imageProviderFactory,
        onLoaded: onLoaded,
        key: key,
        frameBuilder: frameBuilder,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
      );

  static LottieBuilder network(
    String url, {
    Animation<double> controller,
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
        imageProviderFactory: imageProviderFactory,
        onLoaded: onLoaded,
        key: key,
        frameBuilder: frameBuilder,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
      );

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
        progress: _progressAnimation.value,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
      ),
    );
  }
}
