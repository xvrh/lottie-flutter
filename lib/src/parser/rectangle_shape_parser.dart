import 'dart:ui';
import '../../lottie.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_point_value.dart';
import '../model/animatable/animatable_value.dart';
import '../model/content/rectangle_shape.dart';
import 'animatable_path_value_parser.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class RectangleShapeParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['nm', 'p', 's', 'r', 'hd']);

  RectangleShapeParser._();

  static RectangleShape parse(
      JsonReader reader, LottieComposition composition) {
    String? name;
    AnimatableValue<Offset, Offset>? position;
    AnimatablePointValue? size;
    AnimatableDoubleValue? roundedness;
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
          roundedness = AnimatableValueParser.parseFloat(reader, composition);
          break;
        case 4:
          hidden = reader.nextBoolean();
          break;
        default:
          reader.skipValue();
      }
    }

    return RectangleShape(
        name: name,
        position: position!,
        size: size!,
        cornerRadius: roundedness!,
        hidden: hidden);
  }
}
