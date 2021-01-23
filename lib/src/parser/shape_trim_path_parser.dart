import '../../lottie.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/content/shape_trim_path.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class ShapeTrimPathParser {
  ShapeTrimPathParser._();
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['s', 'e', 'o', 'nm', 'm', 'hd']);
  static ShapeTrimPath parse(JsonReader reader, LottieComposition composition) {
    String? name;
    ShapeTrimPathType? type;
    AnimatableDoubleValue? start;
    AnimatableDoubleValue? end;
    AnimatableDoubleValue? offset;
    var hidden = false;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          start = AnimatableValueParser.parseFloat(reader, composition,
              isDp: false);
          break;
        case 1:
          end = AnimatableValueParser.parseFloat(reader, composition,
              isDp: false);
          break;
        case 2:
          offset = AnimatableValueParser.parseFloat(reader, composition,
              isDp: false);
          break;
        case 3:
          name = reader.nextString();
          break;
        case 4:
          type = ShapeTrimPath.typeForId(reader.nextInt());
          break;
        case 5:
          hidden = reader.nextBoolean();
          break;
        default:
          reader.skipValue();
      }
    }

    return ShapeTrimPath(
        name: name,
        type: type!,
        start: start!,
        end: end!,
        offset: offset!,
        hidden: hidden);
  }
}
