import 'package:meta/meta.dart';
import '../animatable/animatable_integer_value.dart';
import '../animatable/animatable_shape_value.dart';

enum MaskMode {
  MASK_MODE_ADD,
  MASK_MODE_SUBTRACT,
  MASK_MODE_INTERSECT,
  MASK_MODE_NONE
}

class Mask {
  final MaskMode maskMode;
  final AnimatableShapeValue maskPath;
  final AnimatableIntegerValue opacity;
  final bool isInverted;

  Mask(
      {@required this.maskMode,
      @required this.maskPath,
      @required this.opacity,
      @required this.isInverted});
}
