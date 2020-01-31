import '../composition.dart';
import '../model/animatable/animatable_color_value.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/content/shape_stroke.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class ShapeStrokeParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['nm', 'c', 'w', 'o', 'lc', 'lj', 'ml', 'hd', 'd']);
  static final JsonReaderOptions _dashPatternNames =
      JsonReaderOptions.of(['n', 'v']);

  ShapeStrokeParser._();

  static ShapeStroke parse(JsonReader reader, LottieComposition composition) {
    String name;
    AnimatableColorValue color;
    AnimatableDoubleValue width;
    AnimatableIntegerValue opacity;
    LineCapType capType;
    LineJoinType joinType;
    AnimatableDoubleValue offset;
    var miterLimit = 0.0;
    var hidden = false;

    var lineDashPattern = <AnimatableDoubleValue>[];

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
          break;
        case 1:
          color = AnimatableValueParser.parseColor(reader, composition);
          break;
        case 2:
          width = AnimatableValueParser.parseFloat(reader, composition);
          break;
        case 3:
          opacity = AnimatableValueParser.parseInteger(reader, composition);
          break;
        case 4:
          capType = LineCapType.values[reader.nextInt() - 1];
          break;
        case 5:
          joinType = LineJoinType.values[reader.nextInt() - 1];
          break;
        case 6:
          miterLimit = reader.nextDouble();
          break;
        case 7:
          hidden = reader.nextBoolean();
          break;
        case 8:
          reader.beginArray();
          while (reader.hasNext()) {
            String n;
            AnimatableDoubleValue val;

            reader.beginObject();
            while (reader.hasNext()) {
              switch (reader.selectName(_dashPatternNames)) {
                case 0:
                  n = reader.nextString();
                  break;
                case 1:
                  val = AnimatableValueParser.parseFloat(reader, composition);
                  break;
                default:
                  reader.skipName();
                  reader.skipValue();
              }
            }
            reader.endObject();

            switch (n) {
              case 'o':
                offset = val;
                break;
              case 'd':
              case 'g':
                composition.hasDashPattern = true;
                lineDashPattern.add(val);
                break;
            }
          }
          reader.endArray();

          if (lineDashPattern.length == 1) {
            // If there is only 1 value then it is assumed to be equal parts on and off.
            lineDashPattern.add(lineDashPattern.first);
          }
          break;
        default:
          reader.skipValue();
      }
    }

    return ShapeStroke(
        name: name,
        dashOffset: offset,
        lineDashPattern: lineDashPattern,
        color: color,
        opacity: opacity,
        width: width,
        capType: capType,
        joinType: joinType,
        miterLimit: miterLimit,
        hidden: hidden);
  }
}
