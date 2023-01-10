import '../../animation/keyframe/gradient_color_keyframe_animation.dart';
import '../../value/keyframe.dart';
import '../content/gradient_color.dart';
import 'base_animatable_value.dart';

class AnimatableGradientColorValue
    extends BaseAnimatableValue<GradientColor, GradientColor> {
  AnimatableGradientColorValue.fromKeyframes(
      List<Keyframe<GradientColor>> keyframes)
      : super.fromKeyframes(_ensureInterpolatableKeyframes(keyframes));

  static List<Keyframe<GradientColor>> _ensureInterpolatableKeyframes(
      List<Keyframe<GradientColor>> keyframes) {
    for (var i = 0; i < keyframes.length; i++) {
      keyframes[i] = _ensureInterpolatableKeyframe(keyframes[i]);
    }
    return keyframes;
  }

  static Keyframe<GradientColor> _ensureInterpolatableKeyframe(
      Keyframe<GradientColor> keyframe) {
    var startValue = keyframe.startValue;
    var endValue = keyframe.endValue;
    if (startValue == null ||
        endValue == null ||
        startValue.positions.length == endValue.positions.length) {
      return keyframe;
    }
    var mergedPositions =
        _mergePositions(startValue.positions, endValue.positions);
    // The start/end has opacity stops which required adding extra positions in between the existing colors.
    return keyframe.copyWith(startValue.copyWithPositions(mergedPositions),
        endValue.copyWithPositions(mergedPositions));
  }

  static List<double> _mergePositions(
      List<double> startPositions, List<double> endPositions) {
    var mergedArray =
        List<double>.filled(startPositions.length + endPositions.length, 0);
    mergedArray.setRange(0, startPositions.length, startPositions);
    mergedArray.setRange(startPositions.length,
        startPositions.length + endPositions.length, endPositions);
    mergedArray.sort();
    var uniqueValues = 0;
    var lastValue = double.nan;
    for (var i = 0; i < mergedArray.length; i++) {
      if (mergedArray[i] != lastValue) {
        mergedArray[uniqueValues] = mergedArray[i];
        uniqueValues++;
        lastValue = mergedArray[i];
      }
    }
    return mergedArray.take(uniqueValues).toList();
  }

  @override
  GradientColorKeyframeAnimation createAnimation() {
    return GradientColorKeyframeAnimation(keyframes);
  }
}
