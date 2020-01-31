import '../value/scale_xy.dart';
import 'moshi/json_reader.dart';

ScaleXY scaleXYParser(JsonReader reader, {double scale}) {
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
  return ScaleXY(sx / 100.0 * scale, sy / 100.0 * scale);
}
