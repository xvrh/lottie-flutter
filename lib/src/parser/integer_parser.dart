import 'json_utils.dart';
import 'moshi/json_reader.dart';

int integerParser(JsonReader reader) {
  return JsonUtils.valueFromObject(reader).round();
}
