import 'dart:ui';
import 'package:lottie/src/model/content/blur_effect.dart';
import 'package:lottie/src/model/layer/composition_layer.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../animation/content/content.dart';
import '../../animation/content/content_group.dart';
import '../../lottie_drawable.dart';
import '../content/shape_group.dart';
import '../key_path.dart';
import 'base_layer.dart';
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
  void drawLayer(Canvas canvas, Size size, Matrix4 parentMatrix,
      {required int parentAlpha}) {
    _contentGroup.draw(canvas, size, parentMatrix, parentAlpha: parentAlpha);
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
  void resolveChildKeyPath(KeyPath keyPath, int depth,
      List<KeyPath> accumulator, KeyPath currentPartialKeyPath) {
    _contentGroup.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath);
  }
}
