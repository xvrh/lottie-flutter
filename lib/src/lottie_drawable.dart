import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';
import 'composition.dart';
import 'model/layer/composition_layer.dart';
import 'parser/layer_parser.dart';

class LottieDrawable {
  final LottieComposition composition;
  final _matrix = Matrix4.identity();
  CompositionLayer _compositionLayer;
  final Size size;

  LottieDrawable(this.composition)
      : size = Size(composition.bounds.width.toDouble(),
            composition.bounds.height.toDouble()) {
    _compositionLayer = CompositionLayer(
        this, LayerParser.parse(composition), composition.layers, composition);
  }

  CompositionLayer get compositionLayer => _compositionLayer;

  bool isApplyingOpacityToLayersEnabled = true;

  void invalidateSelf() {}

  ui.Image getImageAsset(String ref) {
    return null;
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
