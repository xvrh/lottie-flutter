import 'dart:ui';
import '../../model/content/shape_data.dart';
import '../../utils/misc.dart';
import '../../utils/path_factory.dart';
import '../../value/keyframe.dart';
import 'base_keyframe_animation.dart';

class ShapeKeyframeAnimation extends BaseKeyframeAnimation<ShapeData, Path> {
  final ShapeData _tempShapeData = ShapeData.empty();
  final Path _tempPath = PathFactory.create();

  ShapeKeyframeAnimation(List<Keyframe<ShapeData>> keyframes)
      : super(keyframes);

  @override
  Path getValue(Keyframe<ShapeData> keyframe, double keyframeProgress) {
    var startShapeData = keyframe.startValue!;
    var endShapeData = keyframe.endValue!;

    _tempShapeData.interpolateBetween(
        startShapeData, endShapeData, keyframeProgress);
    MiscUtils.getPathFromData(_tempShapeData, _tempPath);
    return _tempPath;
  }
}
