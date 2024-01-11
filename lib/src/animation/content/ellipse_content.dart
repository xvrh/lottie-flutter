import 'dart:ui';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/circle_shape.dart';
import '../../model/content/shape_trim_path.dart';
import '../../model/key_path.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../utils/misc.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/base_keyframe_animation.dart';
import 'compound_trim_path_content.dart';
import 'content.dart';
import 'key_path_element_content.dart';
import 'path_content.dart';
import 'trim_path_content.dart';

class EllipseContent implements PathContent, KeyPathElementContent {
  static const _ellipseControlPointPercentage = 0.55228;

  final Path _path = Path();

  @override
  final String? name;
  final LottieDrawable lottieDrawable;
  final BaseKeyframeAnimation<Object, Offset> _sizeAnimation;
  final BaseKeyframeAnimation<Object, Offset> _positionAnimation;
  final CircleShape _circleShape;

  final CompoundTrimPathContent _trimPaths = CompoundTrimPathContent();
  bool _isPathValid = false;

  EllipseContent(this.lottieDrawable, BaseLayer layer, this._circleShape)
      : name = _circleShape.name,
        _sizeAnimation = _circleShape.size.createAnimation(),
        _positionAnimation = _circleShape.position.createAnimation() {
    layer.addAnimation(_sizeAnimation);
    layer.addAnimation(_positionAnimation);

    _sizeAnimation.addUpdateListener(invalidate);
    _positionAnimation.addUpdateListener(invalidate);
  }

  void invalidate() {
    _isPathValid = false;
    lottieDrawable.invalidateSelf();
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    for (var i = 0; i < contentsBefore.length; i++) {
      var content = contentsBefore[i];
      if (content is TrimPathContent &&
          content.type == ShapeTrimPathType.simultaneously) {
        var trimPath = content;
        _trimPaths.addTrimPath(trimPath);
        trimPath.addListener(invalidate);
      }
    }
  }

  @override
  Path getPath() {
    if (_isPathValid) {
      return _path;
    }

    _path.reset();

    if (_circleShape.hidden) {
      _isPathValid = true;
      return _path;
    }

    var size = _sizeAnimation.value;
    var halfWidth = size.dx / 2.0;
    var halfHeight = size.dy / 2.0;
    // TODO: handle bounds

    var cpW = halfWidth * _ellipseControlPointPercentage;
    var cpH = halfHeight * _ellipseControlPointPercentage;

    _path.reset();
    if (_circleShape.isReversed) {
      _path.moveTo(0, -halfHeight);
      _path.cubicTo(0 - cpW, -halfHeight, -halfWidth, 0 - cpH, -halfWidth, 0);
      _path.cubicTo(-halfWidth, 0 + cpH, 0 - cpW, halfHeight, 0, halfHeight);
      _path.cubicTo(0 + cpW, halfHeight, halfWidth, 0 + cpH, halfWidth, 0);
      _path.cubicTo(halfWidth, 0 - cpH, 0 + cpW, -halfHeight, 0, -halfHeight);
    } else {
      _path.moveTo(0, -halfHeight);
      _path.cubicTo(0 + cpW, -halfHeight, halfWidth, 0 - cpH, halfWidth, 0);
      _path.cubicTo(halfWidth, 0 + cpH, 0 + cpW, halfHeight, 0, halfHeight);
      _path.cubicTo(0 - cpW, halfHeight, -halfWidth, 0 + cpH, -halfWidth, 0);
      _path.cubicTo(-halfWidth, 0 - cpH, 0 - cpW, -halfHeight, 0, -halfHeight);
    }

    var position = _positionAnimation.value;
    _path.offset(position);

    _path.close();

    _trimPaths.apply(_path);

    _isPathValid = true;
    return _path;
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    MiscUtils.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath, this);
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    if (property == LottieProperty.ellipseSize) {
      _sizeAnimation.setValueCallback(callback as LottieValueCallback<Offset>?);
    } else if (property == LottieProperty.position) {
      _positionAnimation
          .setValueCallback(callback as LottieValueCallback<Offset>?);
    }
  }
}
