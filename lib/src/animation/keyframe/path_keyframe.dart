import 'dart:ui';
import '../../composition.dart';
import '../../utils/utils.dart';
import '../../value/keyframe.dart';

class PathKeyframe extends Keyframe<Offset> {
  Path? _path;
  final Keyframe<Offset> _pointKeyFrame;

  PathKeyframe(LottieComposition composition, Keyframe<Offset> keyframe)
      : _pointKeyFrame = keyframe,
        super(composition,
            startValue: keyframe.startValue,
            endValue: keyframe.endValue,
            interpolator: keyframe.interpolator,
            startFrame: keyframe.startFrame,
            endFrame: keyframe.endFrame) {
    createPath();
  }

  void createPath() {
    var equals =
        endValue != null && startValue != null && startValue == endValue;
    if (endValue != null && !equals) {
      _path = Utils.createPath(
          startValue!, endValue!, _pointKeyFrame.pathCp1, _pointKeyFrame.pathCp2);
    }
  }

  /// This will be null if the startValue and endValue are the same. */
  Path? getPath() {
    return _path;
  }
}
