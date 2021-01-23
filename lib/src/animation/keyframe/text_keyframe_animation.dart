import '../../model/document_data.dart';
import '../../value/keyframe.dart';
import 'keyframe_animation.dart';

class TextKeyframeAnimation extends KeyframeAnimation<DocumentData> {
  TextKeyframeAnimation(List<Keyframe<DocumentData>> keyframes)
      : super(keyframes);

  @override
  DocumentData getValue(
      Keyframe<DocumentData> keyframe, double keyframeProgress) {
    return keyframe.startValue!;
  }
}
