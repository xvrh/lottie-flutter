import 'dart:ui';
import 'lottie_frame_info.dart';

double Function(LottieFrameInfo<double>) relativeDoubleValueCallback(
    double offset) {
  return (LottieFrameInfo<double> frameInfo) {
    var originalValue = lerpDouble(frameInfo.startValue, frameInfo.endValue,
        frameInfo.interpolatedKeyframeProgress)!;

    return originalValue + offset;
  };
}
