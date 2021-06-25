import '../composition.dart';
import '../model/content/shape_group.dart';
import '../model/font_character.dart';
import 'content_model_parser.dart';
import 'moshi/json_reader.dart';

class FontCharacterParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['ch', 'size', 'w', 'style', 'fFamily', 'data']);
  static final JsonReaderOptions _dataNames = JsonReaderOptions.of(['shapes']);

  FontCharacterParser._();

  static FontCharacter parse(JsonReader reader, LottieComposition composition) {
    String? character = '';
    var size = 0.0;
    var width = 0.0;
    String? style;
    String? fontFamily;
    var shapes = <ShapeGroup>[];

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          character = reader.nextString();
          break;
        case 1:
          size = reader.nextDouble();
          break;
        case 2:
          width = reader.nextDouble();
          break;
        case 3:
          style = reader.nextString();
          break;
        case 4:
          fontFamily = reader.nextString();
          break;
        case 5:
          reader.beginObject();
          while (reader.hasNext()) {
            switch (reader.selectName(_dataNames)) {
              case 0:
                reader.beginArray();
                while (reader.hasNext()) {
                  shapes.add(ContentModelParser.parse(reader, composition)!
                      as ShapeGroup);
                }
                reader.endArray();
                break;
              default:
                reader.skipName();
                reader.skipValue();
            }
          }
          reader.endObject();
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    return FontCharacter(
        shapes: shapes,
        character: character!,
        size: size,
        width: width,
        style: style ?? '',
        fontFamily: fontFamily ?? '');
  }
}
