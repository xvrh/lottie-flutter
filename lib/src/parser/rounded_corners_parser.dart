import '../composition.dart';
import '../model/animatable/animatable_value.dart';
import '../model/content/rounded_corners.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class RoundedCornersParser {
  static final _names = JsonReaderOptions.of([
    'nm', // 0
    'r', // 1
    'hd' // 1
  ]);

  static RoundedCorners? parse(
      JsonReader reader, LottieComposition composition) {
    String? name;
    AnimatableValue<double, double>? cornerRadius;
    var hidden = false;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0: //nm
          name = reader.nextString();
        case 1: // r
          cornerRadius = AnimatableValueParser.parseFloat(reader, composition);
        case 2: // hd
          hidden = reader.nextBoolean();
        default:
          reader.skipValue();
      }
    }

    return hidden ? null : RoundedCorners(name ?? '', cornerRadius!);
  }
}
