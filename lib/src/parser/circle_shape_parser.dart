import 'dart:ui';
import '../../lottie.dart';
import '../model/animatable/animatable_point_value.dart';
import '../model/animatable/animatable_value.dart';
import '../model/content/circle_shape.dart';
import 'animatable_path_value_parser.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class CircleShapeParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['nm', 'p', 's', 'hd', 'd']);

  CircleShapeParser._();

  static CircleShape parse(
      JsonReader reader, LottieComposition composition, int d) {
    String name;
    AnimatableValue<Offset, Offset> position;
    AnimatablePointValue size;
    var reversed = d == 3;
    var hidden = false;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
          break;
        case 1:
          position =
              AnimatablePathValueParser.parseSplitPath(reader, composition);
          break;
        case 2:
          size = AnimatableValueParser.parsePoint(reader, composition);
          break;
        case 3:
          hidden = reader.nextBoolean();
          break;
        case 4:
          // "d" is 2 for normal and 3 for reversed.
          reversed = reader.nextInt() == 3;
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }

    return CircleShape(
        name: name,
        position: position,
        size: size,
        isReversed: reversed,
        hidden: hidden);
  }
}
