import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../lottie_drawable.dart';
import '../../model/animatable/animatable_transform.dart';
import '../../model/content/content_model.dart';
import '../../model/content/shape_group.dart';
import '../../model/key_path.dart';
import '../../model/key_path_element.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/transform_keyframe_animation.dart';
import 'content.dart';
import 'drawing_content.dart';
import 'greedy_content.dart';
import 'path_content.dart';

class ContentGroup implements DrawingContent, PathContent, KeyPathElement {
  final Paint _offScreenPaint = Paint();

  static List<Content> contentsFromModels(LottieDrawable drawable,
      BaseLayer layer, List<ContentModel> contentModels) {
    var contents = <Content>[];
    for (var i = 0; i < contentModels.length; i++) {
      var content = contentModels[i].toContent(drawable, layer);
      if (content != null) {
        contents.add(content);
      }
    }
    return contents;
  }

  static AnimatableTransform? findTransform(List<ContentModel> contentModels) {
    for (var i = 0; i < contentModels.length; i++) {
      var contentModel = contentModels[i];
      if (contentModel is AnimatableTransform) {
        return contentModel;
      }
    }
    return null;
  }

  final Matrix4 _matrix = Matrix4.identity();
  final Path _path = Path();

  @override
  final String? name;
  final bool _hidden;
  final List<Content> _contents;
  final LottieDrawable _lottieDrawable;
  List<PathContent>? _pathContents;
  TransformKeyframeAnimation? _transformAnimation;

  ContentGroup(
      LottieDrawable lottieDrawable, BaseLayer layer, ShapeGroup shapeGroup)
      : this.copy(
            lottieDrawable,
            layer,
            shapeGroup.name,
            contentsFromModels(lottieDrawable, layer, shapeGroup.items),
            findTransform(shapeGroup.items),
            hidden: shapeGroup.hidden);

  ContentGroup.copy(this._lottieDrawable, BaseLayer layer, this.name,
      this._contents, AnimatableTransform? transform,
      {required bool hidden})
      : _hidden = hidden {
    if (transform != null) {
      _transformAnimation = transform.createAnimation()
        ..addAnimationsToLayer(layer)
        ..addListener(onValueChanged);
    }

    var greedyContents = <GreedyContent>[];
    for (var i = _contents.length - 1; i >= 0; i--) {
      var content = _contents[i];
      if (content is GreedyContent) {
        greedyContents.add(content as GreedyContent);
      }
    }

    for (var i = greedyContents.length - 1; i >= 0; i--) {
      greedyContents[i].absorbContent(_contents);
    }
  }

  void onValueChanged() {
    _lottieDrawable.invalidateSelf();
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    // Do nothing with contents after.
    var myContentsBefore = <Content>[];
    myContentsBefore.addAll(contentsBefore);

    for (var i = _contents.length - 1; i >= 0; i--) {
      var content = _contents[i];
      content.setContents(myContentsBefore, _contents.sublist(0, i));
      myContentsBefore.add(content);
    }
  }

  List<PathContent> getPathList() {
    if (_pathContents == null) {
      var pathContents = _pathContents = <PathContent>[];
      for (var i = 0; i < _contents.length; i++) {
        var content = _contents[i];
        if (content is PathContent) {
          pathContents.add(content);
        }
      }
    }
    return _pathContents!;
  }

  Matrix4 getTransformationMatrix() {
    if (_transformAnimation != null) {
      return _transformAnimation!.getMatrix();
    }
    _matrix.reset();
    return _matrix;
  }

  @override
  Path getPath() {
    // TODO: cache this somehow.
    _matrix.reset();
    if (_transformAnimation != null) {
      _matrix.set(_transformAnimation!.getMatrix());
    }
    _path.reset();
    if (_hidden) {
      return _path;
    }
    for (var i = _contents.length - 1; i >= 0; i--) {
      var content = _contents[i];
      if (content is PathContent) {
        _path.addPath(content.getPath(), Offset.zero, matrix4: _matrix.storage);
      }
    }
    return _path;
  }

  @override
  void draw(Canvas canvas, Matrix4 parentMatrix, {required int parentAlpha}) {
    if (_hidden) {
      return;
    }
    _matrix.set(parentMatrix);
    int layerAlpha;
    if (_transformAnimation != null) {
      _matrix.preConcat(_transformAnimation!.getMatrix());
      var opacity = _transformAnimation?.opacity == null
          ? 100
          : _transformAnimation!.opacity!.value;
      layerAlpha = ((opacity / 100.0 * parentAlpha / 255.0) * 255).round();
    } else {
      layerAlpha = parentAlpha;
    }

    // Apply off-screen rendering only when needed in order to improve rendering performance.
    var isRenderingWithOffScreen =
        _lottieDrawable.isApplyingOpacityToLayersEnabled &&
            hasTwoOrMoreDrawableContent() &&
            layerAlpha != 255;
    if (isRenderingWithOffScreen) {
      var offScreenRect = getBounds(_matrix, applyParents: true);
      _offScreenPaint.setAlpha(layerAlpha);
      canvas.saveLayer(offScreenRect, _offScreenPaint);
    }

    var childAlpha = isRenderingWithOffScreen ? 255 : layerAlpha;
    for (var i = _contents.length - 1; i >= 0; i--) {
      Object content = _contents[i];
      if (content is DrawingContent) {
        content.draw(canvas, _matrix, parentAlpha: childAlpha);
      }
    }

    if (isRenderingWithOffScreen) {
      canvas.restore();
    }
  }

  bool hasTwoOrMoreDrawableContent() {
    var drawableContentCount = 0;
    for (var i = 0; i < _contents.length; i++) {
      if (_contents[i] is DrawingContent) {
        drawableContentCount += 1;
        if (drawableContentCount >= 2) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    _matrix.set(parentMatrix);
    if (_transformAnimation != null) {
      _matrix.preConcat(_transformAnimation!.getMatrix());
    }
    var bounds = Rect.zero;
    for (var i = _contents.length - 1; i >= 0; i--) {
      var content = _contents[i];
      if (content is DrawingContent) {
        var contentBounds =
            content.getBounds(_matrix, applyParents: applyParents);
        bounds = bounds.expandToInclude(contentBounds);
      }
    }
    return bounds;
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    if (!keyPath.matches(name, depth) && name != '__container') {
      return;
    }

    if ('__container' != name && name != null) {
      currentPartialKeyPath = currentPartialKeyPath.addKey(name!);

      if (keyPath.fullyResolvesTo(name, depth)) {
        accumulator.add(currentPartialKeyPath.resolve(this));
      }
    }

    if (keyPath.propagateToChildren(name, depth)) {
      var newDepth = depth + keyPath.incrementDepthBy(name, depth);
      for (var i = 0; i < _contents.length; i++) {
        var content = _contents[i];
        if (content is KeyPathElement) {
          var element = content as KeyPathElement;
          element.resolveKeyPath(
              keyPath, newDepth, accumulator, currentPartialKeyPath);
        }
      }
    }
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    if (_transformAnimation != null) {
      _transformAnimation!.applyValueCallback(property, callback);
    }
  }
}
