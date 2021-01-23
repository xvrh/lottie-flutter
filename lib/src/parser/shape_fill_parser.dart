import 'dart:ui';
import '../../lottie.dart';
import '../model/animatable/animatable_color_value.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/content/shape_fill.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class ShapeFillParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['nm', 'c', 'o', 'fillEnabled', 'r', 'hd']);

  ShapeFillParser._();

  static ShapeFill parse(JsonReader reader, LottieComposition composition) {
    AnimatableColorValue? color;
    var fillEnabled = false;
    AnimatableIntegerValue? opacity;
    String? name;
    var fillTypeInt = 1;
    var hidden = false;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
          break;
        case 1:
          color = AnimatableValueParser.parseColor(reader, composition);
          break;
        case 2:
          opacity = AnimatableValueParser.parseInteger(reader, composition);
          break;
        case 3:
          fillEnabled = reader.nextBoolean();
          break;
        case 4:
          fillTypeInt = reader.nextInt();
          break;
        case 5:
          hidden = reader.nextBoolean();
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }

    var fillType =
        fillTypeInt == 1 ? PathFillType.nonZero : PathFillType.evenOdd;
    return ShapeFill(
        name: name,
        fillEnabled: fillEnabled,
        fillType: fillType,
        color: color,
        opacity: opacity,
        hidden: hidden);
  }
}
