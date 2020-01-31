import 'json_utils.dart';
import 'moshi/json_reader.dart';

int integerParser(JsonReader reader, {double scale}) {
  return (JsonUtils.valueFromObject(reader) * scale).round();
}
