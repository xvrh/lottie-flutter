/// Data class for use with {@link LottieValueCallback}.
class LottieFrameInfo<T> {
  final double startFrame;
  final double? endFrame;
  final T? startValue;
  final T? endValue;
  final double linearKeyframeProgress;
  final double interpolatedKeyframeProgress;
  final double overallProgress;

  LottieFrameInfo(
      this.startFrame,
      this.endFrame,
      this.startValue,
      this.endValue,
      this.linearKeyframeProgress,
      this.interpolatedKeyframeProgress,
      this.overallProgress);
}
