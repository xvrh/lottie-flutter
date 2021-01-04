import '../../lottie.dart';
import '../model/animatable/animatable_shape_value.dart';
import '../model/content/shape_path.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class ShapePathParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['nm', 'ind', 'ks', 'hd']);

  ShapePathParser._();

  static ShapePath parse(JsonReader reader, LottieComposition composition) {
    String? name;
    var ind = 0;
    AnimatableShapeValue? shape;
    var hidden = false;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
          break;
        case 1:
          ind = reader.nextInt();
          break;
        case 2:
          shape = AnimatableValueParser.parseShapeData(reader, composition);
          break;
        case 3:
          hidden = reader.nextBoolean();
          break;
        default:
          reader.skipValue();
      }
    }

    return ShapePath(name: name, index: ind, shapePath: shape!, hidden: hidden);
  }
}
