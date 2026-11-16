import '../../value/keyframe.dart';
import '../keyframe_loop.dart';
import 'animatable_value.dart';

abstract class BaseAnimatableValue<V extends Object, O extends Object>
    implements AnimatableValue<V, O> {
  @override
  final List<Keyframe<V>> keyframes;

  /// The repetition of [keyframes] by a `loopOut` or `loopIn` expression.
  final KeyframeLoop? loop;

  /// Create a default static animatable path.
  BaseAnimatableValue.fromValue(V value)
    : this.fromKeyframes([Keyframe<V>.nonAnimated(value)]);

  BaseAnimatableValue.fromKeyframes(this.keyframes, {this.loop});

  @override
  bool get isStatic {
    return keyframes.isEmpty ||
        (keyframes.length == 1 && keyframes.first.isStatic);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    if (keyframes.isNotEmpty) {
      sb
        ..write('values=')
        ..write('$keyframes');
    }
    return sb.toString();
  }
}
