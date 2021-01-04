import 'dart:ui';
import '../../lottie_drawable.dart';
import '../../model/content/shape_path.dart';
import '../../model/content/shape_trim_path.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../utils/path_factory.dart';
import '../keyframe/base_keyframe_animation.dart';
import 'compound_trim_path_content.dart';
import 'content.dart';
import 'path_content.dart';
import 'trim_path_content.dart';

class ShapeContent implements PathContent {
  final _path = PathFactory.create();

  final ShapePath _shape;

  final LottieDrawable lottieDrawable;
  final BaseKeyframeAnimation<Object, Path> _shapeAnimation;

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
    for (var i = 0; i < contentsBefore.length; i++) {
      var content = contentsBefore[i];
      if (content is TrimPathContent &&
          content.type == ShapeTrimPathType.simultaneously) {
        // Trim path individually will be handled by the stroke where paths are combined.
        var trimPath = content;
        _trimPaths.addTrimPath(trimPath);
        trimPath.addListener(_invalidate);
      }
    }
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
