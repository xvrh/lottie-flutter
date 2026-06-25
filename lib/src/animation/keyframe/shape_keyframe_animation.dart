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
  Path? _valueCallbackStartPath;
  Path? _valueCallbackEndPath;

  ShapeKeyframeAnimation(super.keyframes);

  @override
  Path getValue(Keyframe<ShapeData> keyframe, double keyframeProgress) {
    var startShapeData = keyframe.startValue!;
    var endShapeData = keyframe.endValue;

    _tempShapeData.interpolateBetween(
      startShapeData,
      endShapeData ?? startShapeData,
      keyframeProgress,
    );
    var modifiedShapeData = _tempShapeData;
    var shapeModifiers = _shapeModifiers;
    if (shapeModifiers != null) {
      for (var i = shapeModifiers.length - 1; i >= 0; i--) {
        modifiedShapeData = shapeModifiers[i].modifyShape(modifiedShapeData);
      }
    }
    MiscUtils.getPathFromData(modifiedShapeData, _tempPath);

    var valueCallback = this.valueCallback;
    if (valueCallback != null) {
      var startPath = _valueCallbackStartPath ??= Path();
      var endPath = _valueCallbackEndPath ??= Path();
      MiscUtils.getPathFromData(startShapeData, startPath);
      if (endShapeData != null) {
        MiscUtils.getPathFromData(endShapeData, endPath);
      }
      return valueCallback.getValueInternal(
            keyframe.startFrame,
            keyframe.endFrame,
            startPath,
            endShapeData == null ? startPath : endPath,
            keyframeProgress,
            getLinearCurrentKeyframeProgress(),
            progress,
          ) ??
          _tempPath;
    }

    return _tempPath;
  }

  void setShapeModifiers(List<ShapeModifierContent>? shapeModifiers) {
    _shapeModifiers = shapeModifiers;
  }

  @override
  bool get skipCache {
    // If there are shape modifiers but no animation on the shape itself, the shape animation
    // will think nothing changed and will keep returning its cached value.
    var shapeModifiers = _shapeModifiers;
    return shapeModifiers != null && shapeModifiers.isNotEmpty;
  }
}
