import 'dart:ui';
import '../../animation/content/content.dart';
import '../../animation/content/modifier_content.dart';
import '../../animation/keyframe/transform_keyframe_animation.dart';
import '../../lottie_drawable.dart';
import '../content/content_model.dart';
import '../layer/base_layer.dart';
import 'animatable_double_value.dart';
import 'animatable_integer_value.dart';
import 'animatable_path_value.dart';
import 'animatable_scale_value.dart';
import 'animatable_value.dart';

class AnimatableTransform implements ModifierContent, ContentModel {
  final AnimatablePathValue? anchorPoint;

  final AnimatableValue<Offset, Offset>? position;

  final AnimatableScaleValue? scale;

  final AnimatableDoubleValue? rotation;

  final AnimatableIntegerValue? opacity;

  final AnimatableDoubleValue? skew;

  final AnimatableDoubleValue? skewAngle;

  // Used for repeaters

  final AnimatableDoubleValue? startOpacity;

  final AnimatableDoubleValue? endOpacity;

  bool isAutoOrient = false;

  AnimatableTransform(
      {this.anchorPoint,
      this.position,
      this.scale,
      this.rotation,
      this.opacity,
      this.skew,
      this.skewAngle,
      this.startOpacity,
      this.endOpacity});

  TransformKeyframeAnimation createAnimation() {
    return TransformKeyframeAnimation(this);
  }

  @override
  Content? toContent(LottieDrawable drawable, BaseLayer layer) {
    return null;
  }
}
