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
      ['nm', 'sy', 'pt', 'p', 'r', 'or', 'os', 'ir', 'is', 'hd', 'd']);

  PolystarShapeParser._();

  static PolystarShape parse(JsonReader reader, LottieComposition composition,
      {required int d}) {
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
    var reversed = d == 3;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
        case 1:
          type = PolystarShapeType.forValue(reader.nextInt());
        case 2:
          points = AnimatableValueParser.parseFloat(reader, composition);
        case 3:
          position =
              AnimatablePathValueParser.parseSplitPath(reader, composition);
        case 4:
          rotation = AnimatableValueParser.parseFloat(reader, composition);
        case 5:
          outerRadius = AnimatableValueParser.parseFloat(reader, composition);
        case 6:
          outerRoundedness =
              AnimatableValueParser.parseFloat(reader, composition);
        case 7:
          innerRadius = AnimatableValueParser.parseFloat(reader, composition);
        case 8:
          innerRoundedness =
              AnimatableValueParser.parseFloat(reader, composition);
        case 9:
          hidden = reader.nextBoolean();
        case 10:
          // "d" is 2 for normal and 3 for reversed.
          reversed = reader.nextInt() == 3;
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
      isReversed: reversed,
    );
  }
}
