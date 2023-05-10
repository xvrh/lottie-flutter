import '../composition.dart';
import '../model/content/content_model.dart';
import '../model/content/shape_group.dart';
import 'content_model_parser.dart';
import 'moshi/json_reader.dart';

class ShapeGroupParser {
  ShapeGroupParser._();

  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['nm', 'hd', 'it']);
  static ShapeGroup parse(JsonReader reader, LottieComposition composition) {
    String? name;
    var hidden = false;
    var items = <ContentModel>[];

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
        case 1:
          hidden = reader.nextBoolean();
        case 2:
          reader.beginArray();
          while (reader.hasNext()) {
            var newItem = ContentModelParser.parse(reader, composition);
            if (newItem != null) {
              items.add(newItem);
            }
          }
          reader.endArray();
        default:
          reader.skipValue();
      }
    }

    return ShapeGroup(name, items, hidden: hidden);
  }
}
