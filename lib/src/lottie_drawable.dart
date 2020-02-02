import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'composition.dart';
import 'model/layer/composition_layer.dart';
import 'parser/layer_parser.dart';
import 'text_delegate.dart';

class LottieDrawable {
  final LottieComposition composition;
  final _matrix = Matrix4.identity();
  CompositionLayer _compositionLayer;
  final Size size;
  TextDelegate /*?*/ textDelegate;

  LottieDrawable(this.composition, {this.textDelegate})
      : size = Size(composition.bounds.width.toDouble(),
            composition.bounds.height.toDouble()) {
    _compositionLayer = CompositionLayer(
        this, LayerParser.parse(composition), composition.layers, composition);
  }

  CompositionLayer get compositionLayer => _compositionLayer;

  bool isApplyingOpacityToLayersEnabled = true;

  void invalidateSelf() {}

  bool get useTextGlyphs {
    return textDelegate == null && composition.characters.isNotEmpty;
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
    //TODO(xha): allow the user to map Font in the animation with FontFamily loaded for flutter
    // Support to inherit TextStyle from DefaultTextStyle applied for the Lottie wiget
    return TextStyle(fontFamily: font);
  }

  void draw(ui.Canvas canvas, ui.Rect rect,
      {@required double progress, BoxFit fit, Alignment alignment}) {
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
    progress ??= 0;
    _compositionLayer
      ..setProgress(progress)
      ..draw(canvas, rect.size, _matrix, parentAlpha: 255);
  }
}
