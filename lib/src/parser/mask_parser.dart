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
              break;
            case 's':
              maskMode = MaskMode.maskModeSubstract;
              break;
            case 'n':
              maskMode = MaskMode.maskModeNone;
              break;
            case 'i':
              composition.addWarning(
                  'Animation contains intersect masks. They are not supported but will be treated like add masks.');
              maskMode = MaskMode.maskModeIntersect;
              break;
            default:
              composition.addWarning(
                  'Unknown mask mode $modeName. Defaulting to Add.');
              maskMode = MaskMode.maskModeAdd;
          }
          break;
        case 'pt':
          maskPath = AnimatableValueParser.parseShapeData(reader, composition);
          break;
        case 'o':
          opacity = AnimatableValueParser.parseInteger(reader, composition);
          break;
        case 'inv':
          inverted = reader.nextBoolean();
          break;
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
