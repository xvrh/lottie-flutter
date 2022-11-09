import 'dart:ui';
import 'json_utils.dart';
import 'moshi/json_reader.dart';

Offset offsetParser(JsonReader reader) {
  var token = reader.peek();
  if (token == Token.beginArray) {
    return JsonUtils.jsonToPoint(reader);
  } else if (token == Token.beginObject) {
    return JsonUtils.jsonToPoint(reader);
  } else if (token == Token.number) {
    // This is the case where the static value for a property is an array of numbers.
    // We begin the array to see if we have an array of keyframes but it's just an array
    // of static numbers instead.
    var point = Offset(reader.nextDouble(), reader.nextDouble());
    while (reader.hasNext()) {
      reader.skipValue();
    }
    return point;
  } else {
    throw Exception('Cannot convert json to point. Next token is $token');
  }
}
