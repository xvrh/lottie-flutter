import 'base_keyframe_animation.dart';

abstract class KeyframeAnimation<T extends Object>
    extends BaseKeyframeAnimation<T, T> {
  KeyframeAnimation(super.keyframes);
}
