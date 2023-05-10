import 'dart:ui';
import '../../lottie.dart';
import '../model/animatable/animatable_gradient_color_value.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/animatable/animatable_point_value.dart';
import '../model/content/gradient_fill.dart';
import '../model/content/gradient_type.dart';
import '../value/keyframe.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class GradientFillParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['nm', 'g', 'o', 't', 's', 'e', 'r', 'hd']);
  static final JsonReaderOptions _gradientNames =
      JsonReaderOptions.of(['p', 'k']);

  GradientFillParser._();

  static GradientFill parse(JsonReader reader, LottieComposition composition) {
    String? name;
    AnimatableGradientColorValue? color;
    AnimatableIntegerValue? opacity;
    GradientType? gradientType;
    AnimatablePointValue? startPoint;
    AnimatablePointValue? endPoint;
    var fillType = PathFillType.nonZero;
    var hidden = false;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
        case 1:
          var points = -1;
          reader.beginObject();
          while (reader.hasNext()) {
            switch (reader.selectName(_gradientNames)) {
              case 0:
                points = reader.nextInt();
              case 1:
                color = AnimatableValueParser.parseGradientColor(
                    reader, composition, points);
              default:
                reader.skipName();
                reader.skipValue();
            }
          }
          reader.endObject();
        case 2:
          opacity = AnimatableValueParser.parseInteger(reader, composition);
        case 3:
          gradientType =
              reader.nextInt() == 1 ? GradientType.linear : GradientType.radial;
        case 4:
          startPoint = AnimatableValueParser.parsePoint(reader, composition);
        case 5:
          endPoint = AnimatableValueParser.parsePoint(reader, composition);
        case 6:
          fillType = reader.nextInt() == 1
              ? PathFillType.nonZero
              : PathFillType.evenOdd;
        case 7:
          hidden = reader.nextBoolean();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }

    // Telegram sometimes omits opacity.
    // https://github.com/airbnb/lottie-android/issues/1600
    opacity ??=
        AnimatableIntegerValue.fromKeyframes([Keyframe.nonAnimated(100)]);
    return GradientFill(
      name: name,
      gradientType: gradientType ?? GradientType.linear,
      fillType: fillType,
      gradientColor: color!,
      opacity: opacity,
      startPoint: startPoint!,
      endPoint: endPoint!,
      hidden: hidden,
    );
  }
}
