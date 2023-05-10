import '../composition.dart';
import '../model/content/blur_effect.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class BlurEffectParser {
  static final JsonReaderOptions _blurEffectNames =
      JsonReaderOptions.of(['ef']);
  static final JsonReaderOptions _innerBlurEffectNames =
      JsonReaderOptions.of(['ty', 'v']);

  static BlurEffect? parse(JsonReader reader, LottieComposition composition) {
    BlurEffect? blurEffect;
    while (reader.hasNext()) {
      switch (reader.selectName(_blurEffectNames)) {
        case 0:
          reader.beginArray();
          while (reader.hasNext()) {
            var be = _maybeParseInnerEffect(reader, composition);
            if (be != null) {
              blurEffect = be;
            }
          }
          reader.endArray();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    return blurEffect;
  }

  static BlurEffect? _maybeParseInnerEffect(
      JsonReader reader, LottieComposition composition) {
    BlurEffect? blurEffect;
    var isCorrectType = false;
    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_innerBlurEffectNames)) {
        case 0:
          isCorrectType = reader.nextInt() == 0;
        case 1:
          if (isCorrectType) {
            blurEffect = BlurEffect(
                AnimatableValueParser.parseFloat(reader, composition));
          } else {
            reader.skipValue();
          }
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();
    return blurEffect;
  }
}
