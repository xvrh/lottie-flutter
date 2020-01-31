import '../composition.dart';
import '../logger.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/animatable/animatable_shape_value.dart';
import '../model/content/mask.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class MaskParser {
  MaskParser._();

  static Mask parse(JsonReader reader, LottieComposition composition) {
    MaskMode maskMode;
    AnimatableShapeValue maskPath;
    AnimatableIntegerValue opacity;
    var inverted = false;

    reader.beginObject();
    while (reader.hasNext()) {
      var mode = reader.nextName();
      switch (mode) {
        case 'mode':
          switch (reader.nextString()) {
            case 'a':
              maskMode = MaskMode.MASK_MODE_ADD;
              break;
            case 's':
              maskMode = MaskMode.MASK_MODE_SUBTRACT;
              break;
            case 'n':
              maskMode = MaskMode.MASK_MODE_NONE;
              break;
            case 'i':
              composition.addWarning(
                  'Animation contains intersect masks. They are not supported but will be treated like add masks.');
              maskMode = MaskMode.MASK_MODE_INTERSECT;
              break;
            default:
              logger.warning('Unknown mask mode $mode. Defaulting to Add.');
              maskMode = MaskMode.MASK_MODE_ADD;
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
