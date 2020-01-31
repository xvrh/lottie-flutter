import 'dart:ui';
import 'moshi/json_reader.dart';

Color colorParser(JsonReader reader, {double scale}) {
  var isArray = reader.peek() == Token.beginArray;
  if (isArray) {
    reader.beginArray();
  }
  var r = reader.nextDouble();
  var g = reader.nextDouble();
  var b = reader.nextDouble();
  var a = reader.nextDouble();
  if (isArray) {
    reader.endArray();
  }

  if (r <= 1 && g <= 1 && b <= 1 && a <= 1) {
    r *= 255;
    g *= 255;
    b *= 255;
    a *= 255;
  }

  return Color.fromARGB(a.round(), r.round(), g.round(), b.round());
}
