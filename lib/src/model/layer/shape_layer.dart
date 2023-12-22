import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../animation/content/content.dart';
import '../../animation/content/content_group.dart';
import '../../lottie_drawable.dart';
import '../content/blur_effect.dart';
import '../content/drop_shadow_effect.dart';
import '../content/shape_group.dart';
import '../key_path.dart';
import 'base_layer.dart';
import 'composition_layer.dart';
import 'layer.dart';

class ShapeLayer extends BaseLayer {
  late ContentGroup _contentGroup;
  final CompositionLayer _compositionLayer;

  ShapeLayer(
      LottieDrawable lottieDrawable, Layer layerModel, this._compositionLayer)
      : super(lottieDrawable, layerModel) {
    // Naming this __container allows it to be ignored in KeyPath matching.
    var shapeGroup =
        ShapeGroup('__container', layerModel.shapes, hidden: false);
    _contentGroup = ContentGroup(lottieDrawable, this, shapeGroup)
      ..setContents(<Content>[], <Content>[]);
  }

  @override
  void drawLayer(Canvas canvas, Matrix4 parentMatrix,
      {required int parentAlpha}) {
    _contentGroup.draw(canvas, parentMatrix, parentAlpha: parentAlpha);
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    var bounds = super.getBounds(parentMatrix, applyParents: applyParents);
    bounds = bounds.expandToInclude(
        _contentGroup.getBounds(boundsMatrix, applyParents: applyParents));
    return bounds;
  }

  @override
  BlurEffect? get blurEffect {
    var layerBlur = super.blurEffect;
    if (layerBlur != null) {
      return layerBlur;
    }
    return _compositionLayer.blurEffect;
  }

  @override
  DropShadowEffect? get dropShadowEffect {
    var layerDropShadow = super.dropShadowEffect;
    if (layerDropShadow != null) {
      return layerDropShadow;
    }
    return _compositionLayer.dropShadowEffect;
  }

  @override
  void resolveChildKeyPath(KeyPath keyPath, int depth,
      List<KeyPath> accumulator, KeyPath currentPartialKeyPath) {
    _contentGroup.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath);
  }
}
