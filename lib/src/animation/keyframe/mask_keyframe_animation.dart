import 'dart:ui';
import '../../model/content/mask.dart';
import '../../model/content/shape_data.dart';
import 'base_keyframe_animation.dart';

class MaskKeyframeAnimation {
  final maskAnimations = <BaseKeyframeAnimation<ShapeData, Path>>[];
  final opacityAnimations = <BaseKeyframeAnimation<int, int>>[];
  final List<Mask> masks;

  MaskKeyframeAnimation(this.masks) {
    for (var mask in masks) {
      maskAnimations.add(mask.maskPath.createAnimation());
      opacityAnimations.add(mask.opacity.createAnimation());
    }
  }
}
