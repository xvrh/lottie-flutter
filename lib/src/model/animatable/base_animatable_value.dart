import '../../value/keyframe.dart';
import 'animatable_value.dart';

abstract class BaseAnimatableValue<V, O> implements AnimatableValue<V, O> {
  @override
  final List<Keyframe<V>> keyframes;

  /// Create a default static animatable path.
  BaseAnimatableValue.fromValue(V value)
      : this.fromKeyframes([Keyframe<V>.nonAnimated(value)]);

  BaseAnimatableValue.fromKeyframes(this.keyframes);

  @override
  bool get isStatic {
    return keyframes.isEmpty ||
        (keyframes.length == 1 && keyframes.first.isStatic);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    if (keyframes.isNotEmpty) {
      sb..write('values=')..write('$keyframes');
    }
    return sb.toString();
  }
}
