import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'composition.dart';
import 'frame_rate.dart';
import 'lottie_delegates.dart';
import 'model/key_path.dart';
import 'model/layer/composition_layer.dart';
import 'parser/layer_parser.dart';
import 'utils.dart';
import 'value_delegate.dart';

class LottieDrawable {
  final LottieComposition composition;
  final _matrix = Matrix4.identity();
  late CompositionLayer _compositionLayer;
  final Size size;
  LottieDelegates? _delegates;
  bool _isDirty = true;
  final bool enableMergePaths;

  /// Gives a suggestion whether to paint with anti-aliasing, or not. Default is true.
  bool antiAliasingSuggested = true;

  LottieDrawable(this.composition,
      {LottieDelegates? delegates, bool? enableMergePaths})
      : size = Size(composition.bounds.width.toDouble(),
            composition.bounds.height.toDouble()),
        enableMergePaths = enableMergePaths ?? false {
    this.delegates = delegates;
    _compositionLayer = CompositionLayer(
        this, LayerParser.parse(composition), composition.layers, composition);
  }

  CompositionLayer get compositionLayer => _compositionLayer;

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

  double get progress => _progress ?? 0.0;
  double? _progress;
  bool setProgress(double value, {FrameRate? frameRate}) {
    frameRate ??= FrameRate.composition;
    var roundedProgress =
        composition.roundProgress(value, frameRate: frameRate);
    if (roundedProgress != _progress) {
      _isDirty = false;
      _progress = roundedProgress;
      _compositionLayer.setProgress(roundedProgress);
      return _isDirty;
    } else {
      return false;
    }
  }

  LottieDelegates? get delegates => _delegates;
  set delegates(LottieDelegates? delegates) {
    if (_delegates != delegates) {
      _delegates = delegates;
      _updateValueDelegates(delegates?.values);
    }
  }

  bool get useTextGlyphs {
    return delegates?.text == null && composition.characters.isNotEmpty;
  }

  ui.Image? getImageAsset(String? ref) {
    var imageAsset = composition.images[ref];
    if (imageAsset != null) {
      var imageDelegate = delegates?.image;
      ui.Image? image;
      if (imageDelegate != null) {
        image = imageDelegate(composition, imageAsset);
      }

      return image ?? imageAsset.loadedImage;
    } else {
      return null;
    }
  }

  TextStyle getTextStyle(String font, String style) {
    return (_delegates?.textStyle ?? defaultTextStyleDelegate)(
        LottieFontStyle(fontFamily: font, style: style));
  }

  List<ValueDelegate> _valueDelegates = <ValueDelegate>[];
  void _updateValueDelegates(List<ValueDelegate>? newDelegates) {
    if (identical(_valueDelegates, newDelegates)) return;

    newDelegates ??= const [];

    var delegates = <ValueDelegate>[];

    for (var newDelegate in newDelegates) {
      var existingDelegate = _valueDelegates
          .firstWhereOrNull((f) => f.isSameProperty(newDelegate));
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

  void draw(ui.Canvas canvas, ui.Rect rect,
      {BoxFit? fit, Alignment? alignment}) {
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

    canvas.save();
    canvas.translate(destinationRect.left, destinationRect.top);
    _matrix.setIdentity();
    _matrix.scale(destinationRect.size.width / sourceRect.width,
        destinationRect.size.height / sourceRect.height);
    _compositionLayer.draw(canvas, rect.size, _matrix, parentAlpha: 255);
    canvas.restore();
  }
}

class LottieFontStyle {
  final String fontFamily, style;

  LottieFontStyle({required this.fontFamily, required this.style});
}
