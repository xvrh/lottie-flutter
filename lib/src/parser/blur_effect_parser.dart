import '../composition.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/content/blur_effect.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class BlurEffectParser {
  static final JsonReaderOptions _blurEffectNames = JsonReaderOptions.of([
    'ef',
  ]);
  static final JsonReaderOptions _innerBlurEffectNames = JsonReaderOptions.of([
    'ty',
    'v',
    'nm',
  ]);

  static BlurEffect? parse(JsonReader reader, LottieComposition composition) {
    AnimatableDoubleValue? blurriness;
    AnimatableDoubleValue? dimensions;
    while (reader.hasNext()) {
      switch (reader.selectName(_blurEffectNames)) {
        case 0:
          reader.beginArray();
          while (reader.hasNext()) {
            var property = _parseProperty(reader, composition);
            if (property == null) {
              continue;
            }
            if (property.type == 0) {
              blurriness = property.value;
            } else if (property.type == 7 &&
                property.name == 'Blur Dimensions') {
              dimensions = property.value;
            }
          }
          reader.endArray();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    var blur = blurriness;
    if (blur == null) {
      return null;
    }
    return BlurEffect(blur, dimensions: dimensions);
  }

  static _BlurProperty? _parseProperty(
    JsonReader reader,
    LottieComposition composition,
  ) {
    int? type;
    var name = '';
    AnimatableDoubleValue? value;
    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_innerBlurEffectNames)) {
        case 0:
          type = reader.nextInt();
        case 1:
          value = AnimatableValueParser.parseFloat(reader, composition);
        case 2:
          name = reader.nextString();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();
    if (type == null || value == null) {
      return null;
    }
    return _BlurProperty(type, name, value);
  }
}

class _BlurProperty {
  final int type;
  final String name;
  final AnimatableDoubleValue value;

  _BlurProperty(this.type, this.name, this.value);
}
