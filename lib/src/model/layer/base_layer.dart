import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' hide Layer;
import '../../animation/content/content.dart';
import '../../animation/content/drawing_content.dart';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/double_keyframe_animation.dart';
import '../../animation/keyframe/mask_keyframe_animation.dart';
import '../../animation/keyframe/transform_keyframe_animation.dart';
import '../../composition.dart';
import '../../l.dart';
import '../../lottie_drawable.dart';
import '../../utils.dart';
import '../../value/lottie_value_callback.dart';
import '../content/blur_effect.dart';
import '../content/drop_shadow_effect.dart';
import '../content/mask.dart';
import '../content/shape_data.dart';
import '../key_path.dart';
import '../key_path_element.dart';
import 'composition_layer.dart';
import 'image_layer.dart';
import 'layer.dart';
import 'null_layer.dart';
import 'shape_layer.dart';
import 'solid_layer.dart';
import 'text_layer.dart';

abstract class BaseLayer implements DrawingContent, KeyPathElement {
  static BaseLayer? forModel(
      CompositionLayer compositionLayer,
      Layer layerModel,
      LottieDrawable drawable,
      LottieComposition composition) {
    switch (layerModel.layerType) {
      case LayerType.shape:
        return ShapeLayer(drawable, layerModel, compositionLayer);
      case LayerType.preComp:
        return CompositionLayer(drawable, layerModel,
            composition.getPrecomps(layerModel.refId)!, composition);
      case LayerType.solid:
        return SolidLayer(drawable, layerModel);
      case LayerType.image:
        return ImageLayer(drawable, layerModel);
      case LayerType.nullLayer:
        return NullLayer(drawable, layerModel);
      case LayerType.text:
        return TextLayer(drawable, layerModel);
      case LayerType.unknown:
        // Do nothing
        drawable.composition
            .addWarning('Unknown layer type ${layerModel.layerType}');
        return null;
    }
  }

  final Matrix4 _matrix = Matrix4.identity();
  final Paint _contentPaint = ui.Paint();
  final Paint _dstInPaint = ui.Paint()..blendMode = ui.BlendMode.dstIn;
  final Paint _dstOutPaint = ui.Paint()..blendMode = ui.BlendMode.dstOut;
  final Paint _mattePaint = ui.Paint();
  final Paint _clearPaint = ui.Paint()
    ..isAntiAlias = false
    ..blendMode = ui.BlendMode.clear;
  final String _drawTraceName;
  final Matrix4 boundsMatrix = Matrix4.identity();
  final LottieDrawable lottieDrawable;
  final Layer layerModel;

  MaskKeyframeAnimation? _mask;
  DoubleKeyframeAnimation? _inOutAnimation;
  BaseLayer? _matteLayer;

  /// This should only be used by {@link #buildParentLayerListIfNeeded()}
  /// to construct the list of parent layers.
  BaseLayer? _parentLayer;
  List<BaseLayer>? _parentLayers;

  final List<BaseKeyframeAnimation> _animations = <BaseKeyframeAnimation>[];
  final TransformKeyframeAnimation transform;
  bool _visible = true;

  double blurMaskFilterRadius = 0;
  MaskFilter? blurMaskFilter;

  BaseLayer(this.lottieDrawable, this.layerModel)
      : _drawTraceName = '${layerModel.name}#draw',
        transform = layerModel.transform.createAnimation() {
    if (layerModel.matteType == MatteType.invert) {
      _mattePaint.blendMode = BlendMode.dstOut;
    } else {
      _mattePaint.blendMode = BlendMode.dstIn;
    }

    transform.addListener(invalidateSelf);

    if (layerModel.masks.isNotEmpty) {
      var mask = _mask = MaskKeyframeAnimation(layerModel.masks);
      for (var animation in mask.maskAnimations) {
        // Don't call addAnimation() because progress gets set manually in setProgress to
        // properly handle time scale.
        animation.addUpdateListener(invalidateSelf);
      }
      for (var animation in mask.opacityAnimations) {
        addAnimation(animation);
        animation.addUpdateListener(invalidateSelf);
      }
    }
    _setupInOutAnimations();
  }

  void setMatteLayer(BaseLayer? matteLayer) {
    _matteLayer = matteLayer;
  }

  bool hasMatteOnThisLayer() {
    return _matteLayer != null;
  }

  void setParentLayer(BaseLayer? parentLayer) {
    _parentLayer = parentLayer;
  }

  void _setupInOutAnimations() {
    if (layerModel.inOutKeyframes.isNotEmpty) {
      var inOutAnimation = _inOutAnimation =
          DoubleKeyframeAnimation(layerModel.inOutKeyframes)..setIsDiscrete();
      inOutAnimation.addUpdateListener(() {
        _setVisible(inOutAnimation.value == 1);
      });
      _setVisible(inOutAnimation.value == 1);
      addAnimation(inOutAnimation);
    } else {
      _setVisible(true);
    }
  }

  void invalidateSelf() {
    lottieDrawable.invalidateSelf();
  }

  void addAnimation(BaseKeyframeAnimation? newAnimation) {
    if (newAnimation == null) {
      return;
    }
    _animations.add(newAnimation);
  }

  void removeAnimation(BaseKeyframeAnimation? animation) {
    _animations.remove(animation);
  }

  @mustCallSuper
  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    _buildParentLayerListIfNeeded();
    boundsMatrix.set(parentMatrix);

    if (applyParents) {
      if (_parentLayers != null) {
        for (var i = _parentLayers!.length - 1; i >= 0; i--) {
          boundsMatrix.preConcat(_parentLayers![i].transform.getMatrix());
        }
      } else if (_parentLayer != null) {
        boundsMatrix.preConcat(_parentLayer!.transform.getMatrix());
      }
    }

    boundsMatrix.preConcat(transform.getMatrix());

    return Rect.zero;
  }

  @override
  void draw(Canvas canvas, Matrix4 parentMatrix, {required int parentAlpha}) {
    L.beginSection(_drawTraceName);
    if (!_visible || layerModel.isHidden) {
      L.endSection(_drawTraceName);
      return;
    }
    _buildParentLayerListIfNeeded();
    L.beginSection('Layer#parentMatrix');
    _matrix.reset();
    _matrix.set(parentMatrix);
    for (var i = _parentLayers!.length - 1; i >= 0; i--) {
      _matrix.preConcat(_parentLayers![i].transform.getMatrix());
    }
    L.endSection('Layer#parentMatrix');
    var opacity = transform.opacity?.value ?? 100;
    var alpha = ((parentAlpha / 255.0 * opacity / 100.0) * 255).toInt();
    var blendMode = this.blendMode;
    if (!hasMatteOnThisLayer() && !hasMasksOnThisLayer() && blendMode == null) {
      _matrix.preConcat(transform.getMatrix());
      L.beginSection('Layer#drawLayer');
      drawLayer(canvas, _matrix, parentAlpha: alpha);
      L.endSection('Layer#drawLayer');
      _recordRenderTime(L.endSection(_drawTraceName));
      return;
    }

    L.beginSection('Layer#computeBounds');
    var bounds = getBounds(_matrix, applyParents: false);

    // Uncomment this to draw matte outlines.
    /*var paint = Paint()
      ..color = Color(0xFF00FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(bounds, paint);*/

    bounds = _intersectBoundsWithMatte(bounds, parentMatrix);

    _matrix.preConcat(transform.getMatrix());
    bounds = _intersectBoundsWithMask(bounds, _matrix);

    L.endSection('Layer#computeBounds');

    if (!bounds.isEmpty) {
      L.beginSection('Layer#saveLayer');
      _contentPaint.setAlpha(255);
      _contentPaint.blendMode = blendMode ?? ui.BlendMode.srcOver;
      canvas.saveLayer(bounds, _contentPaint);
      L.endSection('Layer#saveLayer');

      // Clear the off screen buffer. This is necessary for some phones.
      _clearCanvas(canvas, bounds);
      L.beginSection('Layer#drawLayer');
      drawLayer(canvas, _matrix, parentAlpha: alpha);
      L.endSection('Layer#drawLayer');

      if (hasMasksOnThisLayer()) {
        _applyMasks(canvas, bounds, _matrix);
      }

      if (hasMatteOnThisLayer()) {
        L.beginSection('Layer#drawMatte');
        L.beginSection('Layer#saveLayer');
        canvas.saveLayer(bounds, _mattePaint);
        L.endSection('Layer#saveLayer');
        _clearCanvas(canvas, bounds);
        _matteLayer!.draw(canvas, parentMatrix, parentAlpha: alpha);
        L.beginSection('Layer#restoreLayer');
        canvas.restore();
        L.endSection('Layer#restoreLayer');
        L.endSection('Layer#drawMatte');
      }

      L.beginSection('Layer#restoreLayer');
      canvas.restore();
      L.endSection('Layer#restoreLayer');
    }

    _recordRenderTime(L.endSection(_drawTraceName));
  }

  void _recordRenderTime(double ms) {
    lottieDrawable.composition.performanceTracker
        .recordRenderTime(layerModel.name, ms);
  }

  void _clearCanvas(Canvas canvas, Rect bounds) {
    L.beginSection('Layer#clearLayer');
    // If we don't pad the clear draw, some phones leave a 1px border of the graphics buffer.
    canvas.drawRect(bounds.inflate(1), _clearPaint);
    L.endSection('Layer#clearLayer');
  }

  Rect _intersectBoundsWithMask(Rect bounds, Matrix4 matrix) {
    if (!hasMasksOnThisLayer()) {
      return bounds;
    }
    var size = _mask!.masks.length;
    var maskBoundsRect = Rect.zero;
    for (var i = 0; i < size; i++) {
      var mask = _mask!.masks[i];
      BaseKeyframeAnimation<dynamic, Path> maskAnimation =
          _mask!.maskAnimations[i];
      var maskPath = maskAnimation.value;
      var path = maskPath.transform(matrix.storage);

      switch (mask.maskMode) {
        case MaskMode.maskModeNone:
          // Mask mode none will just render the original content so it is the whole bounds.
          return bounds;
        case MaskMode.maskModeSubstract:
          // If there is a subtract mask, the mask could potentially be the size of the entire
          // canvas so we can't use the mask bounds.
          return bounds;
        case MaskMode.maskModeIntersect:
        case MaskMode.maskModeAdd:
          if (mask.isInverted) {
            return bounds;
          }

          var maskBounds = path.getBounds();
          // As we iterate through the masks, we want to calculate the union region of the masks.
          // We initialize the rect with the first mask. If we don't call set() on the first call,
          // the rect will always extend to (0,0).
          if (i == 0) {
            maskBoundsRect = maskBounds;
          } else {
            maskBoundsRect = Rect.fromLTRB(
                min(maskBoundsRect.left, maskBounds.left),
                min(maskBoundsRect.top, maskBounds.top),
                max(maskBoundsRect.right, maskBounds.right),
                max(maskBoundsRect.bottom, maskBounds.bottom));
          }
      }
    }

    var intersects = bounds.intersect(maskBoundsRect);
    if (intersects.isEmpty) {
      return Rect.zero;
    }
    return bounds;
  }

  Rect _intersectBoundsWithMatte(Rect bounds, Matrix4 matrix) {
    if (!hasMatteOnThisLayer()) {
      return bounds;
    }

    if (layerModel.matteType == MatteType.invert) {
      // We can't trim the bounds if the mask is inverted since it extends all the way to the
      // composition bounds.
      return bounds;
    }
    var matteBounds = _matteLayer!.getBounds(matrix, applyParents: true);
    var intersects = bounds.intersect(matteBounds);
    if (intersects.isEmpty) {
      return Rect.zero;
    }
    return bounds;
  }

  void drawLayer(Canvas canvas, Matrix4 parentMatrix,
      {required int parentAlpha});

  void _applyMasks(Canvas canvas, Rect bounds, Matrix4 matrix) {
    L.beginSection('Layer#saveLayer');
    canvas.saveLayer(bounds, _dstInPaint);
    //TODO(xha): check if needed
    //canvas.drawColor(Color(0), BlendMode.dst);

    L.endSection('Layer#saveLayer');
    for (var i = 0; i < _mask!.masks.length; i++) {
      var mask = _mask!.masks[i];
      var maskAnimation = _mask!.maskAnimations[i];
      var opacityAnimation = _mask!.opacityAnimations[i];
      switch (mask.maskMode) {
        case MaskMode.maskModeNone:
          // None mask should have no effect. If all masks are NONE, fill the
          // mask canvas with a rectangle so it fully covers the original layer content.
          // However, if there are other masks, they should be the only ones that have an effect so
          // this should noop.
          if (_areAllMasksNone()) {
            _contentPaint.setAlpha(255);
            canvas.drawRect(bounds, _contentPaint);
          }
        case MaskMode.maskModeAdd:
          if (mask.isInverted) {
            _applyInvertedAddMask(
                canvas, bounds, matrix, mask, maskAnimation, opacityAnimation);
          } else {
            _applyAddMask(
                canvas, matrix, mask, maskAnimation, opacityAnimation);
          }
        case MaskMode.maskModeSubstract:
          if (i == 0) {
            _contentPaint.color = const ui.Color(0xFF000000);
            canvas.drawRect(bounds, _contentPaint);
          }
          if (mask.isInverted) {
            _applyInvertedSubtractMask(
                canvas, bounds, matrix, mask, maskAnimation, opacityAnimation);
          } else {
            _applySubtractMask(
                canvas, matrix, mask, maskAnimation, opacityAnimation);
          }
        case MaskMode.maskModeIntersect:
          if (mask.isInverted) {
            _applyInvertedIntersectMask(
                canvas, bounds, matrix, mask, maskAnimation, opacityAnimation);
          } else {
            _applyIntersectMask(
                canvas, bounds, matrix, mask, maskAnimation, opacityAnimation);
          }
      }
    }
    L.beginSection('Layer#restoreLayer');
    canvas.restore();
    L.endSection('Layer#restoreLayer');
  }

  bool _areAllMasksNone() {
    if (_mask == null || _mask!.maskAnimations.isEmpty) {
      return false;
    }
    for (var i = 0; i < _mask!.masks.length; i++) {
      if (_mask!.masks[i].maskMode != MaskMode.maskModeNone) {
        return false;
      }
    }
    return true;
  }

  void _applyAddMask(
      Canvas canvas,
      Matrix4 matrix,
      Mask mask,
      BaseKeyframeAnimation<ShapeData, Path> maskAnimation,
      BaseKeyframeAnimation<int, int> opacityAnimation) {
    var maskPath = maskAnimation.value;
    var path = maskPath.transform(matrix.storage);
    _contentPaint.setAlpha((opacityAnimation.value * 2.55).round());
    canvas.drawPath(path, _contentPaint);
  }

  void _applyInvertedAddMask(
      Canvas canvas,
      Rect bounds,
      Matrix4 matrix,
      Mask mask,
      BaseKeyframeAnimation<ShapeData, Path> maskAnimation,
      BaseKeyframeAnimation<int, int> opacityAnimation) {
    canvas.saveLayer(bounds, _contentPaint);
    canvas.drawRect(bounds, _contentPaint);
    var maskPath = maskAnimation.value;
    var path = maskPath.transform(matrix.storage);
    _contentPaint.setAlpha((opacityAnimation.value * 2.55).round());
    canvas.drawPath(path, _dstOutPaint);
    canvas.restore();
  }

  void _applySubtractMask(
      Canvas canvas,
      Matrix4 matrix,
      Mask mask,
      BaseKeyframeAnimation<ShapeData, Path> maskAnimation,
      BaseKeyframeAnimation<int, int> opacityAnimation) {
    var maskPath = maskAnimation.value;
    var path = maskPath.transform(matrix.storage);
    canvas.drawPath(path, _dstOutPaint);
  }

  void _applyInvertedSubtractMask(
      Canvas canvas,
      Rect bounds,
      Matrix4 matrix,
      Mask mask,
      BaseKeyframeAnimation<ShapeData, Path> maskAnimation,
      BaseKeyframeAnimation<int, int> opacityAnimation) {
    canvas.saveLayer(bounds, _dstOutPaint);
    canvas.drawRect(bounds, _contentPaint);
    _dstOutPaint.setAlpha((opacityAnimation.value * 2.55).round());

    var maskPath = maskAnimation.value;
    var path = maskPath.transform(matrix.storage);
    canvas.drawPath(path, _dstOutPaint);
    canvas.restore();
  }

  void _applyIntersectMask(
      Canvas canvas,
      Rect bounds,
      Matrix4 matrix,
      Mask mask,
      BaseKeyframeAnimation<ShapeData, Path> maskAnimation,
      BaseKeyframeAnimation<int, int> opacityAnimation) {
    canvas.saveLayer(bounds, _dstInPaint);
    var maskPath = maskAnimation.value;
    var path = maskPath.transform(matrix.storage);
    _contentPaint.setAlpha((opacityAnimation.value * 2.55).round());
    canvas.drawPath(path, _contentPaint);
    canvas.restore();
  }

  void _applyInvertedIntersectMask(
      Canvas canvas,
      Rect bounds,
      Matrix4 matrix,
      Mask mask,
      BaseKeyframeAnimation<ShapeData, Path> maskAnimation,
      BaseKeyframeAnimation<int, int> opacityAnimation) {
    canvas.saveLayer(bounds, _dstInPaint);
    canvas.drawRect(bounds, _contentPaint);
    _dstOutPaint.setAlpha((opacityAnimation.value * 2.55).round());
    var maskPath = maskAnimation.value;
    var path = maskPath.transform(matrix.storage);
    canvas.drawPath(path, _dstOutPaint);
    canvas.restore();
  }

  bool hasMasksOnThisLayer() {
    return _mask != null && _mask!.maskAnimations.isNotEmpty;
  }

  void _setVisible(bool visible) {
    if (visible != _visible) {
      _visible = visible;
      invalidateSelf();
    }
  }

  @protected
  void setProgress(double progress) {
    // Time stretch should not be applied to the layer transform.
    transform.setProgress(progress);
    if (_mask != null) {
      for (var i = 0; i < _mask!.maskAnimations.length; i++) {
        _mask!.maskAnimations[i].setProgress(progress);
      }
    }
    if (_inOutAnimation != null) {
      _inOutAnimation!.setProgress(progress);
    }
    if (_matteLayer != null) {
      _matteLayer!.setProgress(progress);
    }
    for (var i = 0; i < _animations.length; i++) {
      _animations[i].setProgress(progress);
    }
  }

  void _buildParentLayerListIfNeeded() {
    if (_parentLayers != null) {
      return;
    }
    if (_parentLayer == null) {
      _parentLayers = [];
      return;
    }

    _parentLayers = [];
    var layer = _parentLayer;
    while (layer != null) {
      _parentLayers!.add(layer);
      layer = layer._parentLayer;
    }
  }

  @override
  String get name {
    return layerModel.name;
  }

  BlurEffect? get blurEffect {
    return layerModel.blurEffect;
  }

  BlendMode? get blendMode {
    return layerModel.blendMode;
  }

  MaskFilter? getBlurMaskFilter(double radius) {
    if (blurMaskFilterRadius == radius) {
      return blurMaskFilter;
    }
    var sigma = radius * 0.57735 + 0.5;
    blurMaskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
    blurMaskFilterRadius = radius;
    return blurMaskFilter;
  }

  DropShadowEffect? get dropShadowEffect => layerModel.dropShadowEffect;

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    // Do nothing
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    if (keyPath.keys.isEmpty) return;
    var matteLayer = _matteLayer;
    if (matteLayer != null) {
      var matteCurrentPartialKeyPath =
          currentPartialKeyPath.addKey(matteLayer.name);
      if (keyPath.fullyResolvesTo(matteLayer.name, depth)) {
        accumulator.add(matteCurrentPartialKeyPath.resolve(matteLayer));
      }

      if (keyPath.propagateToChildren(name, depth)) {
        var newDepth = depth + keyPath.incrementDepthBy(matteLayer.name, depth);
        matteLayer.resolveChildKeyPath(
            keyPath, newDepth, accumulator, matteCurrentPartialKeyPath);
      }
    }

    if (!keyPath.matches(name, depth)) {
      return;
    }

    if (name != '__container') {
      currentPartialKeyPath = currentPartialKeyPath.addKey(name);

      if (keyPath.fullyResolvesTo(name, depth)) {
        accumulator.add(currentPartialKeyPath.resolve(this));
      }
    }

    if (keyPath.propagateToChildren(name, depth)) {
      var newDepth = depth + keyPath.incrementDepthBy(name, depth);
      resolveChildKeyPath(
          keyPath, newDepth, accumulator, currentPartialKeyPath);
    }
  }

  void resolveChildKeyPath(KeyPath keyPath, int depth,
      List<KeyPath> accumulator, KeyPath currentPartialKeyPath) {}

  @mustCallSuper
  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    transform.applyValueCallback(property, callback);
  }
}
