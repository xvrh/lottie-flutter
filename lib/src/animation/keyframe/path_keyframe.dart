import 'dart:ui';
import '../../composition.dart';
import '../../utils/utils.dart';
import '../../value/keyframe.dart';

class PathKeyframe extends Keyframe<Offset> {
  Path? _path;
  final Keyframe<Offset> _pointKeyFrame;

  PathKeyframe(LottieComposition super.composition, Keyframe<Offset> keyframe)
      : _pointKeyFrame = keyframe,
        super(
            startValue: keyframe.startValue,
            endValue: keyframe.endValue,
            interpolator: keyframe.interpolator,
            xInterpolator: keyframe.xInterpolator,
            yInterpolator: keyframe.yInterpolator,
            startFrame: keyframe.startFrame,
            endFrame: keyframe.endFrame);

  Path? _createPath() {
    var equals =
        endValue != null && startValue != null && startValue == endValue;
    if (startValue != null && endValue != null && !equals) {
      return Utils.createPath(startValue!, endValue!, _pointKeyFrame.pathCp1,
          _pointKeyFrame.pathCp2);
    }
    return null;
  }

  /// This will be null if the startValue and endValue are the same.
  Path? getPath() {
    return _path ??= _createPath();
  }
}
