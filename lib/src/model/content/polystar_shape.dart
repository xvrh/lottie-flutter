import 'dart:ui';
import '../../animation/content/content.dart';
import '../../animation/content/polystar_content.dart';
import '../../lottie_drawable.dart';
import '../animatable/animatable_double_value.dart';
import '../animatable/animatable_value.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

class PolystarShapeType {
  static const star = PolystarShapeType(1);
  static const polygon = PolystarShapeType(2);
  static const List<PolystarShapeType> values = [star, polygon];

  final int value;

  const PolystarShapeType(this.value);

  static PolystarShapeType forValue(int value) {
    for (var type in values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}

class PolystarShape implements ContentModel {
  final String name;
  final PolystarShapeType type;
  final AnimatableDoubleValue points;
  final AnimatableValue<Offset, Offset> position;
  final AnimatableDoubleValue rotation;
  final AnimatableDoubleValue innerRadius;
  final AnimatableDoubleValue outerRadius;
  final AnimatableDoubleValue innerRoundedness;
  final AnimatableDoubleValue outerRoundedness;
  final bool hidden;

  PolystarShape({
    this.name,
    this.type,
    this.points,
    this.position,
    this.rotation,
    this.innerRadius,
    this.outerRadius,
    this.innerRoundedness,
    this.outerRoundedness,
    this.hidden,
  });

  @override
  Content toContent(LottieDrawable drawable, BaseLayer layer) {
    return PolystarContent(drawable, layer, this);
  }
}
