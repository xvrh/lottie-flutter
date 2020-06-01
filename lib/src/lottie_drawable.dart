import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';
import 'composition.dart';
import 'lottie_delegates.dart';
import 'model/key_path.dart';
import 'model/layer/composition_layer.dart';
import 'parser/layer_parser.dart';
import 'value_delegate.dart';

class LottieDrawable {
  final LottieComposition composition;
  final _matrix = Matrix4.identity();
  CompositionLayer _compositionLayer;
  final Size size;
  LottieDelegates _delegates;
  bool _isDirty = true;
  final bool enableMergePaths;

  LottieDrawable(this.composition,
      {LottieDelegates delegates, bool enableMergePaths})
      : size = Size(composition.bounds.width.toDouble(),
            composition.bounds.height.toDouble()),
        enableMergePaths = enableMergePaths ?? false {
    this.delegates = delegates;
    _compositionLayer = CompositionLayer(
        this, LayerParser.parse(composition), composition.layers, composition);
  }

  /// Sets whether to apply opacity to the each layer instead of shape.
  ///
  /// Opacity is normally applied directly to a shape. In cases where translucent
  /// shapes overlap, applying opacity to a layer will be more accurate at the
  /// expense of performance.
  ///
  /// The default value is false.
  ///
  /// Note: This process is very expensive. The performance impact will be reduced
  /// when hardware acceleration is enabled.
  bool isApplyingOpacityToLayersEnabled = false;

  void invalidateSelf() {
    _isDirty = true;
  }

  double get progress => _progress;
  double _progress = 0.0;
  bool setProgress(double value) {
    _isDirty = false;
    _progress = value;
    _compositionLayer.setProgress(value);
    return _isDirty;
  }

  LottieDelegates get delegates => _delegates;
  set delegates(LottieDelegates delegates) {
    delegates ??= LottieDelegates();
    if (_delegates != delegates) {
      _delegates = delegates;
      _updateValueDelegates(delegates.values);
    }
  }

  bool get useTextGlyphs {
    return delegates.text == null && composition.characters.isNotEmpty;
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
    return _delegates
        .textStyle(LottieFontStyle(fontFamily: font, style: style));
  }

  List<ValueDelegate> _valueDelegates = <ValueDelegate>[];
  void _updateValueDelegates(List<ValueDelegate> newDelegates) {
    if (identical(_valueDelegates, newDelegates)) return;

    newDelegates ??= const [];

    var delegates = <ValueDelegate>[];

    for (var newDelegate in newDelegates) {
      var existingDelegate = _valueDelegates
          .firstWhere((f) => f.isSameProperty(newDelegate), orElse: () => null);
      if (existingDelegate != null) {
        var resolved = internalResolved(existingDelegate);
        resolved.updateDelegate(newDelegate);
        delegates.add(existingDelegate);
      } else {
        var keyPaths = _resolveKeyPath(KeyPath(newDelegate.keyPath));
        var resolvedValueDelegate = internalResolve(newDelegate, keyPaths);
        resolvedValueDelegate.addValueCallback(this);
        delegates.add(newDelegate);
      }
    }
    for (var oldDelegate in _valueDelegates) {
      if (delegates.every((c) => !c.isSameProperty(oldDelegate))) {
        var resolved = internalResolved(oldDelegate);
        resolved.clear();
      }
    }
    _valueDelegates = delegates;
  }

  /// Takes a {@link KeyPath}, potentially with wildcards or globstars and resolve it to a list of
  /// zero or more actual {@link KeyPath Keypaths} that exist in the current animation.
  /// <p>
  /// If you want to set value callbacks for any of these values, it is recommend to use the
  /// returned {@link KeyPath} objects because they will be internally resolved to their content
  /// and won't trigger a tree walk of the animation contents when applied.
  List<KeyPath> _resolveKeyPath(KeyPath keyPath) {
    var keyPaths = <KeyPath>[];
    _compositionLayer.resolveKeyPath(keyPath, 0, keyPaths, KeyPath([]));
    return keyPaths;
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

class LottieFontStyle {
  final String fontFamily, style;

  LottieFontStyle({this.fontFamily, this.style});
}
