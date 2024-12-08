import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../l.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../model/content/drop_shadow_effect.dart';
import '../../model/content/shape_fill.dart';
import '../../model/key_path.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../utils/misc.dart';
import '../../value/drop_shadow.dart';
import '../../value/lottie_value_callback.dart';
import '../keyframe/base_keyframe_animation.dart';
import '../keyframe/drop_shadow_keyframe_animation.dart';
import '../keyframe/value_callback_keyframe_animation.dart';
import 'content.dart';
import 'drawing_content.dart';
import 'key_path_element_content.dart';
import 'path_content.dart';

class FillContent implements DrawingContent, KeyPathElementContent {
  final Path _path = Path();
  final BaseLayer layer;
  @override
  final String? name;
  final bool _hidden;
  final List<PathContent> _paths = <PathContent>[];
  late final BaseKeyframeAnimation<Color, Color> _colorAnimation;
  late final BaseKeyframeAnimation<int, int> _opacityAnimation;
  BaseKeyframeAnimation<ColorFilter, ColorFilter?>? _colorFilterAnimation;
  final LottieDrawable lottieDrawable;
  BaseKeyframeAnimation<double, double>? _blurAnimation;
  double _blurMaskFilterRadius = 0;
  DropShadowKeyframeAnimation? dropShadowAnimation;

  FillContent(this.lottieDrawable, this.layer, ShapeFill fill)
      : name = fill.name,
        _hidden = fill.hidden {
    var blurEffect = layer.blurEffect;
    if (blurEffect != null) {
      _blurAnimation = blurEffect.blurriness.createAnimation()
        ..addUpdateListener(onValueChanged);
      layer.addAnimation(_blurAnimation);
    }
    var dropShadowEffect = layer.dropShadowEffect;
    if (dropShadowEffect != null) {
      dropShadowAnimation =
          DropShadowKeyframeAnimation(onValueChanged, layer, dropShadowEffect);
    }

    if (fill.color == null || fill.opacity == null) {
      return;
    }

    _path.fillType = fill.fillType;

    _colorAnimation = fill.color!.createAnimation();
    _colorAnimation.addUpdateListener(onValueChanged);
    layer.addAnimation(_colorAnimation);
    _opacityAnimation = fill.opacity!.createAnimation();
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
    if (_hidden) {
      return;
    }
    L.beginSection('FillContent#draw');

    var paint = Paint()..color = _colorAnimation.value;
    var alpha =
        ((parentAlpha / 255.0 * _opacityAnimation.value / 100.0) * 255).round();
    paint.setAlpha(alpha.clamp(0, 255));
    if (lottieDrawable.antiAliasingSuggested) {
      paint.isAntiAlias = true;
    }

    if (_colorFilterAnimation != null) {
      paint.colorFilter = _colorFilterAnimation!.value;
    }

    var blurAnimation = _blurAnimation;
    if (blurAnimation != null) {
      var blurRadius = blurAnimation.value;
      if (blurRadius == 0) {
        paint.maskFilter = null;
      } else if (blurRadius != _blurMaskFilterRadius) {
        var blur = layer.getBlurMaskFilter(blurRadius);
        paint.maskFilter = blur;
      }
      _blurMaskFilterRadius = blurRadius;
    }

    _path.reset();
    for (var i = 0; i < _paths.length; i++) {
      _path.addPath(_paths[i].getPath(), Offset.zero);
    }

    canvas.save();
    canvas.transform(parentMatrix.storage);
    var dropShadow = dropShadowAnimation;
    if (dropShadow != null) {
      dropShadow.draw(canvas, _path);
    }
    canvas.drawPath(_path, paint);
    canvas.restore();

    L.endSection('FillContent#draw');
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    _path.reset();
    for (var i = 0; i < _paths.length; i++) {
      _path.addPath(_paths[i].getPath(), Offset.zero,
          matrix4: parentMatrix.storage);
    }
    var outBounds = _path.getBounds();
    // Add padding to account for rounding errors.
    outBounds = outBounds.inflate(1);
    return outBounds;
  }

  @override
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath) {
    MiscUtils.resolveKeyPath(
        keyPath, depth, accumulator, currentPartialKeyPath, this);
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
            callback as LottieValueCallback<ColorFilter>, null)
          ..addUpdateListener(onValueChanged);
        layer.addAnimation(_colorFilterAnimation);
      }
    } else if (property == LottieProperty.blurRadius) {
      var blurAnimation = _blurAnimation;
      if (blurAnimation != null) {
        blurAnimation
            .setValueCallback(callback as LottieValueCallback<double>?);
      } else {
        var callbackBlur = callback as LottieValueCallback<double>?;
        _blurAnimation = blurAnimation = ValueCallbackKeyframeAnimation(
            callbackBlur, callbackBlur?.value ?? 0)
          ..addUpdateListener(onValueChanged);
        layer.addAnimation(blurAnimation);
      }
    } else if (property == LottieProperty.dropShadow) {
      var dropShadowAnimation = this.dropShadowAnimation;
      if (dropShadowAnimation == null) {
        var effect = DropShadowEffect.createEmpty();
        this.dropShadowAnimation = dropShadowAnimation = dropShadowAnimation =
            DropShadowKeyframeAnimation(onValueChanged, layer, effect);
      }

      dropShadowAnimation
          .setCallback(callback as LottieValueCallback<DropShadow>?);
    }
  }
}
