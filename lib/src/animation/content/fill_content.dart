import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../l.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/shape_fill.dart';
import '../../model/key_path.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../utils/misc.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/base_keyframe_animation.dart';
import '../keyframe/value_callback_keyframe_animation.dart';
import 'content.dart';
import 'drawing_content.dart';
import 'key_path_element_content.dart';
import 'path_content.dart';

class FillContent implements DrawingContent, KeyPathElementContent {
  final Path _path = Path();
  final BaseLayer layer;
  final ShapeFill _fill;
  final List<PathContent> _paths = <PathContent>[];
  late final BaseKeyframeAnimation<Color, Color> _colorAnimation;
  late final BaseKeyframeAnimation<int, int> _opacityAnimation;
  BaseKeyframeAnimation<ColorFilter, ColorFilter?>? _colorFilterAnimation;
  final LottieDrawable lottieDrawable;

  @override
  String? get name => _fill.name;

  FillContent(this.lottieDrawable, this.layer, this._fill) {
    if (_fill.color == null || _fill.opacity == null) {
      return;
    }

    _colorAnimation = _fill.color!.createAnimation();
    _colorAnimation.addUpdateListener(onValueChanged);
    layer.addAnimation(_colorAnimation);
    _opacityAnimation = _fill.opacity!.createAnimation();
    _opacityAnimation.addUpdateListener(onValueChanged);
    layer.addAnimation(_opacityAnimation);
  }

  void onValueChanged() {
    lottieDrawable.invalidateSelf();
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    for (var i = 0; i < contentsAfter.length; i++) {
      var content = contentsAfter[i];
      if (content is PathContent) {
        _paths.add(content);
      }
    }
  }

  @override
  void draw(Canvas canvas, Matrix4 parentMatrix, {required int parentAlpha}) {
    if (_fill.hidden) {
      return;
    }
    L.beginSection('FillContent#draw');

    var paint = Paint()..color = _colorAnimation.value;
    var alpha = ((parentAlpha / 255.0 * _opacityAnimation.value / 100.0) * 255)
        .round();
    paint.setAlpha(alpha.clamp(0, 255));
    if (lottieDrawable.antiAliasingSuggested) {
      paint.isAntiAlias = true;
    }

    if (_colorFilterAnimation != null) {
      paint.colorFilter = _colorFilterAnimation!.value;
    }

    _path.reset();
    _path.fillType = _fill.fillType;
    for (var i = 0; i < _paths.length; i++) {
      _path.addPath(_paths[i].getPath(), Offset.zero);
    }

    canvas.save();
    canvas.transform(parentMatrix.storage);
    canvas.drawPath(_path, paint);
    canvas.restore();

    L.endSection('FillContent#draw');
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    _path.reset();
    _path.fillType = _fill.fillType;
    for (var i = 0; i < _paths.length; i++) {
      _path.addPath(
        _paths[i].getPath(),
        Offset.zero,
        matrix4: parentMatrix.storage,
      );
    }
    var outBounds = _path.getBounds();
    // Add padding to account for rounding errors.
    outBounds = outBounds.inflate(1);
    return outBounds;
  }

  @override
  void resolveKeyPath(
    KeyPath keyPath,
    int depth,
    List<KeyPath> accumulator,
    KeyPath currentPartialKeyPath,
  ) {
    MiscUtils.resolveKeyPath(
      keyPath,
      depth,
      accumulator,
      currentPartialKeyPath,
      this,
    );
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    if (property == LottieProperty.color) {
      _colorAnimation.setValueCallback(callback as LottieValueCallback<Color>?);
    } else if (property == LottieProperty.opacity) {
      _opacityAnimation.setValueCallback(callback as LottieValueCallback<int>?);
    } else if (property == LottieProperty.colorFilter) {
      if (_colorFilterAnimation != null) {
        layer.removeAnimation(_colorFilterAnimation);
      }

      if (callback == null) {
        _colorFilterAnimation = null;
      } else {
        _colorFilterAnimation = ValueCallbackKeyframeAnimation(
          callback as LottieValueCallback<ColorFilter>,
          null,
        )..addUpdateListener(onValueChanged);
        layer.addAnimation(_colorFilterAnimation);
      }
    }
  }
}
