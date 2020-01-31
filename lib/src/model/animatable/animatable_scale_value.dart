import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/scale_keyframe_animation.dart';
import '../../value/keyframe.dart';
import '../../value/scale_xy.dart';
import 'base_animatable_value.dart';

class AnimatableScaleValue extends BaseAnimatableValue<ScaleXY, ScaleXY> {
  AnimatableScaleValue.one() : this(ScaleXY.one());

  AnimatableScaleValue(ScaleXY value) : super.fromValue(value);

  AnimatableScaleValue.fromKeyframes(List<Keyframe<ScaleXY>> keyframes)
      : super.fromKeyframes(keyframes);

  @override
  BaseKeyframeAnimation<ScaleXY, ScaleXY> createAnimation() {
    return ScaleKeyframeAnimation(keyframes);
  }
}
