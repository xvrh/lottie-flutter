import 'dart:ui';
import 'json_utils.dart';
import 'moshi/json_reader.dart';

Offset pathParser(JsonReader reader, {double scale}) {
  return JsonUtils.jsonToPoint(reader, scale);
}
