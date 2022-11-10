import '../../animation/keyframe/text_keyframe_animation.dart';
import '../document_data.dart';
import 'base_animatable_value.dart';

class AnimatableTextFrame
    extends BaseAnimatableValue<DocumentData, DocumentData> {
  AnimatableTextFrame.fromKeyframes(super.keyframes) : super.fromKeyframes();

  @override
  TextKeyframeAnimation createAnimation() {
    return TextKeyframeAnimation(keyframes);
  }
}
