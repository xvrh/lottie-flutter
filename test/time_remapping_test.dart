import 'dart:convert';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('does not stretch remapped child time', () async {
    // The remap freezes child frame 50. Stretching that result again would
    // select frame 25, outside the red layer's [40, 60) visibility range.
    var pixel = await _renderCenterPixel(includeTimeRemapping: true);

    expect(pixel, const Color(0xffff0000));
  });

  test('continues to stretch child time without remapping', () async {
    var pixel = await _renderCenterPixel(includeTimeRemapping: false);

    expect(pixel, const Color(0x00000000));
  });
}

Future<Color> _renderCenterPixel({required bool includeTimeRemapping}) async {
  var timeRemapping = includeTimeRemapping ? '"tm": {"a": 0, "k": 5},' : '';
  var composition = await LottieComposition.fromBytes(
    utf8.encode('''
{
  "v": "5.7.4",
  "fr": 10,
  "ip": 0,
  "op": 100,
  "w": 10,
  "h": 10,
  "assets": [
    {
      "id": "precomp",
      "layers": [
        {
          "ty": 1,
          "ind": 1,
          "nm": "Red solid",
          "sw": 10,
          "sh": 10,
          "sc": "#ff0000",
          "ip": 40,
          "op": 60,
          "st": 0,
          "sr": 1,
          "ks": {
            "o": {"a": 0, "k": 100},
            "r": {"a": 0, "k": 0},
            "p": {"a": 0, "k": [0, 0, 0]},
            "a": {"a": 0, "k": [0, 0, 0]},
            "s": {"a": 0, "k": [100, 100, 100]}
          }
        }
      ]
    }
  ],
  "layers": [
    {
      "ty": 0,
      "ind": 1,
      "nm": "Stretched precomp",
      "refId": "precomp",
      "w": 10,
      "h": 10,
      "ip": 0,
      "op": 100,
      "st": 0,
      "sr": 2,
      $timeRemapping
      "ks": {
        "o": {"a": 0, "k": 100},
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
  var drawable = LottieDrawable(composition)..setProgress(0.5);
  var recorder = PictureRecorder();
  var canvas = Canvas(recorder);
  drawable.draw(canvas, const Rect.fromLTWH(0, 0, 10, 10));
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
