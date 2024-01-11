import 'dart:ui';
import '../../lottie_drawable.dart';
import '../../model/content/shape_path.dart';
import '../../model/content/shape_trim_path.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../keyframe/shape_keyframe_animation.dart';
import 'compound_trim_path_content.dart';
import 'content.dart';
import 'path_content.dart';
import 'shape_modifier_content.dart';
import 'trim_path_content.dart';

class ShapeContent implements PathContent {
  final _path = Path();

  final ShapePath _shape;

  final LottieDrawable lottieDrawable;
  final ShapeKeyframeAnimation _shapeAnimation;

  bool _isPathValid = false;
  final _trimPaths = CompoundTrimPathContent();

  ShapeContent(this.lottieDrawable, BaseLayer layer, this._shape)
      : _shapeAnimation = _shape.shapePath.createAnimation() {
    layer.addAnimation(_shapeAnimation);
    _shapeAnimation.addUpdateListener(_invalidate);
  }

  void _invalidate() {
    _isPathValid = false;
    lottieDrawable.invalidateSelf();
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    List<ShapeModifierContent>? shapeModifierContents;
    for (var i = 0; i < contentsBefore.length; i++) {
      var content = contentsBefore[i];
      if (content is TrimPathContent &&
          content.type == ShapeTrimPathType.simultaneously) {
        // Trim path individually will be handled by the stroke where paths are combined.
        var trimPath = content;
        _trimPaths.addTrimPath(trimPath);
        trimPath.addListener(_invalidate);
      } else if (content is ShapeModifierContent) {
        shapeModifierContents ??= [];
        shapeModifierContents.add(content);
      }
    }
    _shapeAnimation.setShapeModifiers(shapeModifierContents);
  }

  @override
  String? get name => _shape.name;

  @override
  Path getPath() {
    if (_isPathValid) {
      return _path;
    }

    _path.reset();

    if (_shape.hidden) {
      _isPathValid = true;
      return _path;
    }

    _path.set(_shapeAnimation.value);
    _path.fillType = PathFillType.evenOdd;

    _trimPaths.apply(_path);

    _isPathValid = true;
    return _path;
  }
}
