import '../../animation/keyframe/text_keyframe_animation.dart';
import '../../value/keyframe.dart';
import '../document_data.dart';
import 'base_animatable_value.dart';

class AnimatableTextFrame
    extends BaseAnimatableValue<DocumentData, DocumentData> {
  AnimatableTextFrame.fromKeyframes(List<Keyframe<DocumentData>> keyframes)
      : super.fromKeyframes(keyframes);

  @override
  TextKeyframeAnimation createAnimation() {
    return TextKeyframeAnimation(keyframes);
  }
}
