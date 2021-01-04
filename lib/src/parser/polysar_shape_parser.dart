import 'dart:ui';
import '../composition.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_value.dart';
import '../model/content/polystar_shape.dart';
import 'animatable_path_value_parser.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class PolystarShapeParser {
  static final JsonReaderOptions _names = JsonReaderOptions.of(
      ['nm', 'sy', 'pt', 'p', 'r', 'or', 'os', 'ir', 'is', 'hd']);

  PolystarShapeParser._();

  static PolystarShape parse(JsonReader reader, LottieComposition composition) {
    String? name;
    PolystarShapeType? type;
    late AnimatableDoubleValue points;
    late AnimatableValue<Offset, Offset> position;
    late AnimatableDoubleValue rotation;
    late AnimatableDoubleValue outerRadius;
    late AnimatableDoubleValue outerRoundedness;
    AnimatableDoubleValue? innerRadius;
    AnimatableDoubleValue? innerRoundedness;
    var hidden = false;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
          break;
        case 1:
          type = PolystarShapeType.forValue(reader.nextInt());
          break;
        case 2:
          points = AnimatableValueParser.parseFloat(reader, composition,
              isDp: false);
          break;
        case 3:
          position =
              AnimatablePathValueParser.parseSplitPath(reader, composition);
          break;
        case 4:
          rotation = AnimatableValueParser.parseFloat(reader, composition,
              isDp: false);
          break;
        case 5:
          outerRadius = AnimatableValueParser.parseFloat(reader, composition);
          break;
        case 6:
          outerRoundedness = AnimatableValueParser.parseFloat(
              reader, composition,
              isDp: false);
          break;
        case 7:
          innerRadius = AnimatableValueParser.parseFloat(reader, composition);
          break;
        case 8:
          innerRoundedness = AnimatableValueParser.parseFloat(
              reader, composition,
              isDp: false);
          break;
        case 9:
          hidden = reader.nextBoolean();
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }

    return PolystarShape(
      name: name,
      type: type,
      points: points,
      position: position,
      rotation: rotation,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      innerRoundedness: innerRoundedness,
      outerRoundedness: outerRoundedness,
      hidden: hidden,
    );
  }
}
