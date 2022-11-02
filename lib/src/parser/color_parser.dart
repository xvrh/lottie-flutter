import 'dart:ui';
import 'moshi/json_reader.dart';

Color colorParser(JsonReader reader) {
  var isArray = reader.peek() == Token.beginArray;
  if (isArray) {
    reader.beginArray();
  }
  var r = reader.nextDouble();
  var g = reader.nextDouble();
  var b = reader.nextDouble();
  var a = 1.0;

  // Sometimes, Lottie editors only export rgb instead of rgba.
  // https://github.com/airbnb/lottie-android/issues/1601
  if (reader.peek() == Token.number) {
    a = reader.nextDouble();
  }

  if (isArray) {
    reader.endArray();
  }

  if (r <= 1 && g <= 1 && b <= 1) {
    r *= 255;
    g *= 255;
    b *= 255;
    // It appears as if sometimes, Telegram Lottie stickers are exported with rgb [0,1] and a [0,255].
    // This shouldn't happen but we can gracefully handle it when it does.
    // https://github.com/airbnb/lottie-android/issues/1478
    if (a <= 1) a *= 255;
  }

  return Color.fromARGB(a.round(), r.round(), g.round(), b.round());
}
