import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'lottie_options.dart';
import 'package:vector_math/vector_math_64.dart';
import 'composition.dart';
import 'model/layer/composition_layer.dart';
import 'parser/layer_parser.dart';

class LottieDrawable {
  final LottieComposition composition;
  final _matrix = Matrix4.identity();
  CompositionLayer _compositionLayer;
  final Size size;
  LottieOptions _options;
  bool _isDirty = true;

  LottieDrawable(this.composition, {LottieOptions options})
      : _options = options ?? LottieOptions(),
        size = Size(composition.bounds.width.toDouble(),
            composition.bounds.height.toDouble()) {
    _compositionLayer = CompositionLayer(
        this, LayerParser.parse(composition), composition.layers, composition);
  }

  CompositionLayer get compositionLayer => _compositionLayer;

  /// Sets whether to apply opacity to the each layer instead of shape.
  ///
  /// Opacity is normally applied directly to a shape. In cases where translucent shapes overlap, applying opacity to a layer will be more accurate
  /// at the expense of performance.
  ///
  /// The default value is false.
  ///
  /// Note: This process is very expensive. The performance impact will be reduced when hardware acceleration is enabled.
  bool isApplyingOpacityToLayersEnabled = false;

  void invalidateSelf() {
    _isDirty = true;
  }

  bool setProgress(double value) {
    _isDirty = false;
    _compositionLayer.setProgress(value);
    return _isDirty;
  }

  LottieOptions get options => _options;
  set options(LottieOptions options) {
    options ??= LottieOptions();
    if (_options != options) {
      _options = options;
    }
  }

  bool get useTextGlyphs {
    return options.textDelegate == null && composition.characters.isNotEmpty;
  }

  ui.Image getImageAsset(String ref) {
    var imageAsset = composition.images[ref];
    if (imageAsset != null) {
      return imageAsset.loadedImage;
    } else {
      return null;
    }
  }

  TextStyle getTextStyle(String font, String style) {
    // Bold, Medium, Regular, SemiBold,

    var fontFamily = _options.fontDelegate(font) ?? font;
    print('$font $style');

    //TODO(xha): allow the user to map Font in the animation with FontFamily loaded for flutter
    // Support to inherit TextStyle from DefaultTextStyle applied for the Lottie wiget
    var textStyle = TextStyle(fontFamily: fontFamily);

    return textStyle;
  }

  void draw(ui.Canvas canvas, ui.Rect rect, {BoxFit fit, Alignment alignment}) {
    if (rect.isEmpty) {
      return;
    }

    fit ??= BoxFit.scaleDown;
    alignment ??= Alignment.center;
    var outputSize = rect.size;
    var inputSize = size;
    var fittedSizes = applyBoxFit(fit, inputSize, outputSize);
    var sourceSize = fittedSizes.source;
    var destinationSize = fittedSizes.destination;
    var halfWidthDelta = (outputSize.width - destinationSize.width) / 2.0;
    var halfHeightDelta = (outputSize.height - destinationSize.height) / 2.0;
    var dx = halfWidthDelta + alignment.x * halfWidthDelta;
    var dy = halfHeightDelta + alignment.y * halfHeightDelta;
    var destinationPosition = rect.topLeft.translate(dx, dy);
    var destinationRect = destinationPosition & destinationSize;
    var sourceRect = alignment.inscribe(sourceSize, Offset.zero & inputSize);

    _matrix.setIdentity();
    _matrix.translate(destinationRect.left, destinationRect.top);
    _matrix.scale(destinationRect.size.width / sourceRect.width,
        destinationRect.size.height / sourceRect.height);
    _compositionLayer.draw(canvas, rect.size, _matrix, parentAlpha: 255);
  }
}
