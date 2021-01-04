import '../model/content/merge_paths.dart';
import 'moshi/json_reader.dart';

class MergePathsParser {
  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['nm', 'mm', 'hd']);

  MergePathsParser._();

  static MergePaths parse(JsonReader reader) {
    String? name;
    late MergePathsMode mode;
    var hidden = false;

    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          name = reader.nextString();
          break;
        case 1:
          mode = MergePaths.modeForId(reader.nextInt());
          break;
        case 2:
          hidden = reader.nextBoolean();
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }

    return MergePaths(name: name ?? '', mode: mode, hidden: hidden);
  }
}
