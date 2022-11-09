import 'dart:ui';
import 'moshi/json_reader.dart';

Offset scaleXYParser(JsonReader reader) {
  var isArray = reader.peek() == Token.beginArray;
  if (isArray) {
    reader.beginArray();
  }
  var sx = reader.nextDouble();
  var sy = reader.nextDouble();
  while (reader.hasNext()) {
    reader.skipValue();
  }
  if (isArray) {
    reader.endArray();
  }
  return Offset(sx / 100.0, sy / 100.0);
}
