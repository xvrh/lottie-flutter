import 'dart:ui';
import 'moshi/json_reader.dart';

class JsonUtils {
  static Color jsonToColor(JsonReader reader) {
    reader.beginArray();
    var r = (reader.nextDouble() * 255).round();
    var g = (reader.nextDouble() * 255).round();
    var b = (reader.nextDouble() * 255).round();
    while (reader.hasNext()) {
      reader.skipValue();
    }
    reader.endArray();
    return Color.fromARGB(255, r, g, b);
  }

  static List<Offset> jsonToPoints(JsonReader reader) {
    var points = <Offset>[];

    reader.beginArray();
    while (reader.peek() == Token.beginArray) {
      reader.beginArray();
      points.add(jsonToPoint(reader));
      reader.endArray();
    }
    reader.endArray();
    return points;
  }

  static Offset jsonToPoint(JsonReader reader) {
    switch (reader.peek()) {
      case Token.number:
        return _jsonNumbersToPoint(reader);
      case Token.beginArray:
        return _jsonArrayToPoint(reader);
      case Token.beginObject:
        return _jsonObjectToPoint(reader);
      case Token.nullToken:
        return Offset.zero;
      case Token.endArray:
      case Token.endObject:
      case Token.name:
      case Token.string:
      case Token.boolean:
      case Token.endDocument:
        throw Exception('Unknown point starts with ${reader.peek()}');
    }
  }

  static Offset _jsonNumbersToPoint(JsonReader reader) {
    var x = reader.nextDouble();
    var y = reader.nextDouble();
    while (reader.hasNext()) {
      reader.skipValue();
    }
    return Offset(x, y);
  }

  static Offset _jsonArrayToPoint(JsonReader reader) {
    double x;
    double y;
    reader.beginArray();
    x = reader.nextDouble();
    y = reader.nextDouble();
    while (reader.peek() != Token.endArray) {
      reader.skipValue();
    }
    reader.endArray();
    return Offset(x, y);
  }

  static final JsonReaderOptions _pointNames = JsonReaderOptions.of(['x', 'y']);

  static Offset _jsonObjectToPoint(JsonReader reader) {
    var x = 0.0;
    var y = 0.0;
    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_pointNames)) {
        case 0:
          x = valueFromObject(reader);
        case 1:
          y = valueFromObject(reader);
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();
    return Offset(x, y);
  }

  static double valueFromObject(JsonReader reader) {
    var token = reader.peek();
    switch (token) {
      case Token.number:
        return reader.nextDouble();
      case Token.beginArray:
        reader.beginArray();
        var val = reader.nextDouble();
        while (reader.hasNext()) {
          reader.skipValue();
        }
        reader.endArray();
        return val;
      case Token.endArray:
      case Token.beginObject:
      case Token.endObject:
      case Token.name:
      case Token.string:
      case Token.boolean:
      case Token.nullToken:
      case Token.endDocument:
        throw Exception('Unknown value for token of type $token');
    }
  }
}
