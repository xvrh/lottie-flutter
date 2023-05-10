import '../composition.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/animatable/animatable_shape_value.dart';
import '../model/content/mask.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class MaskParser {
  MaskParser._();

  static Mask parse(JsonReader reader, LottieComposition composition) {
    late MaskMode maskMode;
    late AnimatableShapeValue maskPath;
    late AnimatableIntegerValue opacity;
    var inverted = false;

    reader.beginObject();
    while (reader.hasNext()) {
      var mode = reader.nextName();
      switch (mode) {
        case 'mode':
          var modeName = reader.nextString();
          switch (modeName) {
            case 'a':
              maskMode = MaskMode.maskModeAdd;
            case 's':
              maskMode = MaskMode.maskModeSubstract;
            case 'n':
              maskMode = MaskMode.maskModeNone;
            case 'i':
              composition.addWarning(
                  'Animation contains intersect masks. They are not supported but will be treated like add masks.');
              maskMode = MaskMode.maskModeIntersect;
            default:
              composition.addWarning(
                  'Unknown mask mode $modeName. Defaulting to Add.');
              maskMode = MaskMode.maskModeAdd;
          }
        case 'pt':
          maskPath = AnimatableValueParser.parseShapeData(reader, composition);
        case 'o':
          opacity = AnimatableValueParser.parseInteger(reader, composition);
        case 'inv':
          inverted = reader.nextBoolean();
        default:
          reader.skipValue();
      }
    }
    reader.endObject();

    return Mask(
        maskMode: maskMode,
        maskPath: maskPath,
        opacity: opacity,
        isInverted: inverted);
  }
}
