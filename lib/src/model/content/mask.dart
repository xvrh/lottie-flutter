import '../animatable/animatable_integer_value.dart';
import '../animatable/animatable_shape_value.dart';

enum MaskMode {
  maskModeAdd,
  maskModeSubstract,
  maskModeIntersect,
  maskModeNone
}

class Mask {
  final MaskMode maskMode;
  final AnimatableShapeValue maskPath;
  final AnimatableIntegerValue opacity;
  final bool isInverted;

  Mask(
      {required this.maskMode,
      required this.maskPath,
      required this.opacity,
      required this.isInverted});
}
