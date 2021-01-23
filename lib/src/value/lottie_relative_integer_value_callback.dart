import 'dart:ui';
import 'lottie_frame_info.dart';

int Function(LottieFrameInfo<int>) relativeIntegerValueCallback(int offset) {
  return (LottieFrameInfo<int> frameInfo) {
    var originalValue = lerpDouble(frameInfo.startValue, frameInfo.endValue,
        frameInfo.interpolatedKeyframeProgress)!;

    return (originalValue + offset).round();
  };
}
