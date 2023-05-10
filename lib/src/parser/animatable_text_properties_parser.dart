import '../composition.dart';
import '../model/animatable/animatable_color_value.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_text_properties.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class AnimatableTextPropertiesParser {
  static final JsonReaderOptions _propertiesNames = JsonReaderOptions.of(['a']);
  static final JsonReaderOptions _animatablePropertiesNames =
      JsonReaderOptions.of(['fc', 'sc', 'sw', 't']);

  AnimatableTextPropertiesParser();

  static AnimatableTextProperties parse(
      JsonReader reader, LottieComposition composition) {
    AnimatableTextProperties? anim;

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_propertiesNames)) {
        case 0:
          anim = _parseAnimatableTextProperties(reader, composition);
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();
    if (anim == null) {
      // Not sure if this is possible.
      return AnimatableTextProperties();
    }
    return anim;
  }

  static AnimatableTextProperties _parseAnimatableTextProperties(
      JsonReader reader, LottieComposition composition) {
    AnimatableColorValue? color;
    AnimatableColorValue? stroke;
    AnimatableDoubleValue? strokeWidth;
    AnimatableDoubleValue? tracking;

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_animatablePropertiesNames)) {
        case 0:
          color = AnimatableValueParser.parseColor(reader, composition);
        case 1:
          stroke = AnimatableValueParser.parseColor(reader, composition);
        case 2:
          strokeWidth = AnimatableValueParser.parseFloat(reader, composition);
        case 3:
          tracking = AnimatableValueParser.parseFloat(reader, composition);
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    return AnimatableTextProperties(
        color: color,
        stroke: stroke,
        strokeWidth: strokeWidth,
        tracking: tracking);
  }
}
