import 'dart:ui';
import '../../lottie.dart';
import '../model/animatable/animatable_color_value.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/content/shape_fill.dart';
import '../value/keyframe.dart';
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
        case 1:
          color = AnimatableValueParser.parseColor(reader, composition);
        case 2:
          opacity = AnimatableValueParser.parseInteger(reader, composition);
        case 3:
          fillEnabled = reader.nextBoolean();
        case 4:
          fillTypeInt = reader.nextInt();
        case 5:
          hidden = reader.nextBoolean();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }

    var fillType =
        fillTypeInt == 1 ? PathFillType.nonZero : PathFillType.evenOdd;
    // Telegram sometimes omits opacity.
    // https://github.com/airbnb/lottie-android/issues/1600
    opacity ??=
        AnimatableIntegerValue.fromKeyframes([Keyframe.nonAnimated(100)]);
    return ShapeFill(
        name: name,
        fillEnabled: fillEnabled,
        fillType: fillType,
        color: color,
        opacity: opacity,
        hidden: hidden);
  }
}
