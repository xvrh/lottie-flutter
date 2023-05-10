import '../model/font.dart';
import 'moshi/json_reader.dart';

class FontParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['fFamily', 'fName', 'fStyle', 'ascent']);

  FontParser._();

  static Font parse(JsonReader reader) {
    String? family;
    String? name;
    String? style;
    var ascent = 0.0;

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          family = reader.nextString();
        case 1:
          name = reader.nextString();
        case 2:
          style = reader.nextString();
        case 3:
          ascent = reader.nextDouble();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    return Font(
        family: family ?? '',
        name: name ?? '',
        style: style ?? '',
        ascent: ascent);
  }
}
