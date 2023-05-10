import '../../lottie.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_transform.dart';
import '../model/content/repeater.dart';
import 'animatable_transform_parser.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class RepeaterParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['nm', 'c', 'o', 'tr', 'hd']);

  RepeaterParser._();

  static Repeater parse(JsonReader reader, LottieComposition composition) {
    String? name;
    AnimatableDoubleValue? copies;
    AnimatableDoubleValue? offset;
    AnimatableTransform? transform;
    var hidden = false;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
        case 1:
          copies = AnimatableValueParser.parseFloat(reader, composition);
        case 2:
          offset = AnimatableValueParser.parseFloat(reader, composition);
        case 3:
          transform = AnimatableTransformParser.parse(reader, composition);
        case 4:
          hidden = reader.nextBoolean();
        default:
          reader.skipValue();
      }
    }

    return Repeater(
        name: name,
        copies: copies!,
        offset: offset!,
        transform: transform!,
        hidden: hidden);
  }
}
