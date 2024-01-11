import 'dart:ui';
import '../../model/content/shape_data.dart';
import '../../utils/misc.dart';
import '../../value/keyframe.dart';
import '../content/shape_modifier_content.dart';
import 'base_keyframe_animation.dart';

class ShapeKeyframeAnimation extends BaseKeyframeAnimation<ShapeData, Path> {
  final ShapeData _tempShapeData = ShapeData.empty();
  final Path _tempPath = Path();
  List<ShapeModifierContent>? _shapeModifiers;

  ShapeKeyframeAnimation(super.keyframes);

  @override
  Path getValue(Keyframe<ShapeData> keyframe, double keyframeProgress) {
    var startShapeData = keyframe.startValue!;
    var endShapeData = keyframe.endValue ?? startShapeData;

    _tempShapeData.interpolateBetween(
        startShapeData, endShapeData, keyframeProgress);
    var modifiedShapeData = _tempShapeData;
    var shapeModifiers = _shapeModifiers;
    if (shapeModifiers != null) {
      for (var i = shapeModifiers.length - 1; i >= 0; i--) {
        modifiedShapeData = shapeModifiers[i].modifyShape(modifiedShapeData);
      }
    }
    MiscUtils.getPathFromData(modifiedShapeData, _tempPath);
    return _tempPath;
  }

  void setShapeModifiers(List<ShapeModifierContent>? shapeModifiers) {
    _shapeModifiers = shapeModifiers;
  }
}
