import 'json_utils.dart';
import 'moshi/json_reader.dart';

double floatParser(JsonReader reader) {
  return JsonUtils.valueFromObject(reader);
}
