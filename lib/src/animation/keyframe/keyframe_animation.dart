import '../../value/keyframe.dart';
import 'base_keyframe_animation.dart';

abstract class KeyframeAnimation<T extends Object >
    extends BaseKeyframeAnimation<T, T> {
  KeyframeAnimation(List<Keyframe<T>> keyframes) : super(keyframes);
}
