import 'dart:ui';
import '../../animation/keyframe/split_dimension_path_keyframe_animation.dart';
import '../../value/keyframe.dart';
import 'animatable_double_value.dart';
import 'animatable_value.dart';

class AnimatableSplitDimensionPathValue
    implements AnimatableValue<Offset, Offset> {
  final AnimatableDoubleValue _animatableXDimension;
  final AnimatableDoubleValue _animatableYDimension;

  AnimatableSplitDimensionPathValue(
    this._animatableXDimension,
    this._animatableYDimension,
  );

  @override
  List<Keyframe<Offset>> get keyframes {
    throw UnsupportedError(
      'Cannot call getKeyframes on AnimatableSplitDimensionPathValue.',
    );
  }

  @override
  bool get isStatic {
    return _animatableXDimension.isStatic && _animatableYDimension.isStatic;
  }

  @override
  SplitDimensionPathKeyframeAnimation createAnimation() {
    return SplitDimensionPathKeyframeAnimation(
      _animatableXDimension.createAnimation(),
      _animatableYDimension.createAnimation(),
    );
  }
}
