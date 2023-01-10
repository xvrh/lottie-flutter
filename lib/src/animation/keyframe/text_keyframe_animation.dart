import '../../model/document_data.dart';
import '../../value/keyframe.dart';
import '../../value/lottie_frame_info.dart';
import '../../value/lottie_value_callback.dart';
import 'keyframe_animation.dart';

class TextKeyframeAnimation extends KeyframeAnimation<DocumentData> {
  TextKeyframeAnimation(super.keyframes);

  @override
  DocumentData getValue(
      Keyframe<DocumentData> keyframe, double keyframeProgress) {
    var valueCallback = this.valueCallback;
    if (valueCallback != null) {
      return valueCallback.getValueInternal(
          keyframe.startFrame,
          keyframe.endFrame ?? double.maxFinite,
          keyframe.startValue,
          keyframe.endValue ?? keyframe.startValue,
          keyframeProgress,
          getInterpolatedCurrentKeyframeProgress(),
          progress)!;
    } else if (keyframeProgress != 1.0 || keyframe.endValue == null) {
      return keyframe.startValue!;
    } else {
      return keyframe.endValue!;
    }
  }

  void setStringValueCallback(LottieValueCallback<String> valueCallback) {
    super.setValueCallback(_DocumentDataValueCallback(valueCallback));
  }
}

class _DocumentDataValueCallback extends LottieValueCallback<DocumentData> {
  final LottieValueCallback<String> valueCallback;

  _DocumentDataValueCallback(this.valueCallback) : super(null);

  @override
  DocumentData getValue(LottieFrameInfo<DocumentData> frameInfo) {
    var stringFrameInfo = LottieFrameInfo<String>(
        frameInfo.startFrame,
        frameInfo.endFrame,
        frameInfo.startValue!.text,
        frameInfo.endValue!.text,
        frameInfo.linearKeyframeProgress,
        frameInfo.interpolatedKeyframeProgress,
        frameInfo.overallProgress);
    var text = valueCallback.getValue(stringFrameInfo)!;
    var baseDocumentData = frameInfo.interpolatedKeyframeProgress == 1
        ? frameInfo.endValue!
        : frameInfo.startValue!;
    return DocumentData(
      text: text,
      fontName: baseDocumentData.fontName,
      size: baseDocumentData.size,
      justification: baseDocumentData.justification,
      tracking: baseDocumentData.tracking,
      lineHeight: baseDocumentData.lineHeight,
      baselineShift: baseDocumentData.baselineShift,
      color: baseDocumentData.color,
      strokeColor: baseDocumentData.strokeColor,
      strokeWidth: baseDocumentData.strokeWidth,
      strokeOverFill: baseDocumentData.strokeOverFill,
      boxPosition: baseDocumentData.boxPosition,
      boxSize: baseDocumentData.boxSize,
    );
  }
}
