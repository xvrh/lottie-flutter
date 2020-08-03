class FrameRate {
  static final max = FrameRate._special(0);
  static final composition = FrameRate._special(-1);

  final double framesPerSecond;

  FrameRate(this.framesPerSecond) : assert(framesPerSecond > 0);
  FrameRate._special(this.framesPerSecond);
}
