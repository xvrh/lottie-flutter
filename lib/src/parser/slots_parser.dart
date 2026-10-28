import 'dart:convert';

import 'moshi/json_reader.dart';

/// Reads the `slots` of a Lottie file: a property with a `sid` takes the value
/// of the slot with that id (see `KeyframesParser.slotReader`).
class SlotsParser {
  SlotsParser._();

  /// Returns the property (`p`) of each slot, as JSON bytes.
  static Map<String, List<int>> parse(JsonReader reader) {
    var slots = <String, List<int>>{};
    reader.beginObject();
    while (reader.hasNext()) {
      var id = reader.nextName();
      if (reader.peek() != Token.beginObject) {
        reader.skipValue();
        continue;
      }
      reader.beginObject();
      while (reader.hasNext()) {
        if (reader.nextName() == 'p' && reader.peek() == Token.beginObject) {
          var json = StringBuffer();
          // A slot doesn't take the value of another slot.
          _copy(reader, json, skipName: 'sid');
          slots[id] = utf8.encode(json.toString());
        } else {
          reader.skipValue();
        }
      }
      reader.endObject();
    }
    reader.endObject();
    return slots;
  }

  /// Writes the next value of [reader] to [json], numbers as they are written,
  /// without the entry named [skipName] if it is an object.
  static void _copy(JsonReader reader, StringBuffer json, {String? skipName}) {
    switch (reader.peek()) {
      case Token.beginObject:
        reader.beginObject();
        json.write('{');
        var first = true;
        while (reader.hasNext()) {
          var name = reader.nextName();
          if (name == skipName) {
            reader.skipValue();
            continue;
          }
          if (!first) json.write(',');
          first = false;
          json
            ..write(jsonEncode(name))
            ..write(':');
          _copy(reader, json);
        }
        reader.endObject();
        json.write('}');
      case Token.beginArray:
        reader.beginArray();
        json.write('[');
        for (var first = true; reader.hasNext(); first = false) {
          if (!first) json.write(',');
          _copy(reader, json);
        }
        reader.endArray();
        json.write(']');
      case Token.string:
        json.write(jsonEncode(reader.nextString()));
      case Token.number:
        json.write(reader.nextString());
      case Token.boolean:
        json.write(reader.nextBoolean());
      case Token.nullToken:
      case Token.endArray:
      case Token.endObject:
      case Token.name:
      case Token.endDocument:
        reader.skipValue();
        json.write('null');
    }
  }
}
