import 'dart:ui';
import 'lottie_frame_info.dart';

Offset Function(LottieFrameInfo<Offset>) relativeOffsetValueCallback(
    Offset offset) {
  return (LottieFrameInfo<Offset> frameInfo) {
    var point = Offset.lerp(frameInfo.startValue, frameInfo.endValue,
        frameInfo.interpolatedKeyframeProgress)!;

    return point.translate(offset.dx, offset.dy);
  };
}
