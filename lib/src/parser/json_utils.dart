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

  static List<Offset> jsonToPoints(JsonReader reader, double scale) {
    var points = <Offset>[];

    reader.beginArray();
    while (reader.peek() == Token.beginArray) {
      reader.beginArray();
      points.add(jsonToPoint(reader, scale));
      reader.endArray();
    }
    reader.endArray();
    return points;
  }

  static Offset jsonToPoint(JsonReader reader, double scale) {
    switch (reader.peek()) {
      case Token.number:
        return _jsonNumbersToPoint(reader, scale);
      case Token.beginArray:
        return _jsonArrayToPoint(reader, scale);
      case Token.beginObject:
        return _jsonObjectToPoint(reader, scale: scale);
      // ignore: no_default_cases
      default:
        throw Exception('Unknown point starts with ${reader.peek()}');
    }
  }

  static Offset _jsonNumbersToPoint(JsonReader reader, double scale) {
    var x = reader.nextDouble();
    var y = reader.nextDouble();
    while (reader.hasNext()) {
      reader.skipValue();
    }
    return Offset(x * scale, y * scale);
  }

  static Offset _jsonArrayToPoint(JsonReader reader, double scale) {
    double x;
    double y;
    reader.beginArray();
    x = reader.nextDouble();
    y = reader.nextDouble();
    while (reader.peek() != Token.endArray) {
      reader.skipValue();
    }
    reader.endArray();
    return Offset(x * scale, y * scale);
  }

  static final JsonReaderOptions _pointNames = JsonReaderOptions.of(['x', 'y']);

  static Offset _jsonObjectToPoint(JsonReader reader, {required double scale}) {
    var x = 0.0;
    var y = 0.0;
    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_pointNames)) {
        case 0:
          x = valueFromObject(reader);
          break;
        case 1:
          y = valueFromObject(reader);
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();
    return Offset(x * scale, y * scale);
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
      // ignore: no_default_cases
      default:
        throw Exception('Unknown value for token of type $token');
    }
  }
}
