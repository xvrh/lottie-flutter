import '../../lottie.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_gradient_color_value.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/animatable/animatable_point_value.dart';
import '../model/content/gradient_stroke.dart';
import '../model/content/gradient_type.dart';
import '../model/content/shape_stroke.dart';
import '../value/keyframe.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class GradientStrokeParser {
  GradientStrokeParser._();
  static final JsonReaderOptions _names = JsonReaderOptions.of(
      ['nm', 'g', 'o', 't', 's', 'e', 'w', 'lc', 'lj', 'ml', 'hd', 'd']);
  static final JsonReaderOptions _gradientNames =
      JsonReaderOptions.of(['p', 'k']);
  static final JsonReaderOptions _dashPatternNames =
      JsonReaderOptions.of(['n', 'v']);

  static GradientStroke parse(
      JsonReader reader, LottieComposition composition) {
    String? name;
    AnimatableGradientColorValue? color;
    AnimatableIntegerValue? opacity;
    GradientType? gradientType;
    AnimatablePointValue? startPoint;
    AnimatablePointValue? endPoint;
    AnimatableDoubleValue? width;
    LineCapType? capType;
    LineJoinType? joinType;
    AnimatableDoubleValue? offset;
    var miterLimit = 0.0;
    var hidden = false;

    var lineDashPattern = <AnimatableDoubleValue>[];

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
          width = AnimatableValueParser.parseFloat(reader, composition);
        case 7:
          capType = LineCapType.values[reader.nextInt() - 1];
        case 8:
          joinType = LineJoinType.values[reader.nextInt() - 1];
        case 9:
          miterLimit = reader.nextDouble();
        case 10:
          hidden = reader.nextBoolean();
        case 11:
          reader.beginArray();
          while (reader.hasNext()) {
            String? n;
            AnimatableDoubleValue? val;
            reader.beginObject();
            while (reader.hasNext()) {
              switch (reader.selectName(_dashPatternNames)) {
                case 0:
                  n = reader.nextString();
                case 1:
                  val = AnimatableValueParser.parseFloat(reader, composition);
                default:
                  reader.skipName();
                  reader.skipValue();
              }
            }
            reader.endObject();

            if (n == 'o') {
              offset = val;
            } else if (n == 'd' || n == 'g') {
              composition.hasDashPattern = true;
              lineDashPattern.add(val!);
            }
          }
          reader.endArray();
          if (lineDashPattern.length == 1) {
            // If there is only 1 value then it is assumed to be equal parts on and off.
            lineDashPattern.add(lineDashPattern[0]);
          }
        default:
          reader.skipName();
          reader.skipValue();
      }
    }

    // Telegram sometimes omits opacity.
    // https://github.com/airbnb/lottie-android/issues/1600
    opacity ??=
        AnimatableIntegerValue.fromKeyframes([Keyframe.nonAnimated(100)]);
    return GradientStroke(
        name: name,
        gradientType: gradientType ?? GradientType.linear,
        gradientColor: color!,
        opacity: opacity,
        startPoint: startPoint!,
        endPoint: endPoint!,
        width: width!,
        capType: capType,
        joinType: joinType,
        miterLimit: miterLimit,
        lineDashPattern: lineDashPattern,
        dashOffset: offset,
        hidden: hidden);
  }
}
