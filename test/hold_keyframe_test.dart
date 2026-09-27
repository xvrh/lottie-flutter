import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('a terminal keyframe changes the value after a hold', () async {
    expect(await _renderCenterPixel(0.25), const Color(0x00000000));
    expect(await _renderCenterPixel(0.75), const Color(0xffff0000));
  });
}

Future<Color> _renderCenterPixel(double progress) async {
  var composition = LottieComposition.parseJsonBytes(
    utf8.encode('''
{
  "v": "5.7.4",
  "fr": 10,
  "ip": 0,
  "op": 20,
  "w": 10,
  "h": 10,
  "layers": [
    {
      "ty": 1,
      "ind": 1,
      "nm": "Red solid",
      "sw": 10,
      "sh": 10,
      "sc": "#ff0000",
      "ip": 0,
      "op": 20,
      "st": 0,
      "sr": 1,
      "ks": {
        "o": {
          "a": 1,
          "k": [
            {"t": 0, "s": [0], "h": 1},
            {"t": 10, "s": [100]}
          ]
        },
        "r": {"a": 0, "k": 0},
        "p": {"a": 0, "k": [0, 0, 0]},
        "a": {"a": 0, "k": [0, 0, 0]},
        "s": {"a": 0, "k": [100, 100, 100]}
      }
    }
  ]
}
'''),
  );
  var drawable = LottieDrawable(composition)..setProgress(progress);
  var recorder = PictureRecorder();
  drawable.draw(Canvas(recorder), const Rect.fromLTWH(0, 0, 10, 10));
  var picture = recorder.endRecording();
  var image = await picture.toImage(10, 10);
  var pixels = await image.toByteData();
  var centerOffset = (5 * 10 + 5) * 4;
  var color = Color.fromARGB(
    pixels!.getUint8(centerOffset + 3),
    pixels.getUint8(centerOffset),
    pixels.getUint8(centerOffset + 1),
    pixels.getUint8(centerOffset + 2),
  );
  image.dispose();
  picture.dispose();
  return color;
}
