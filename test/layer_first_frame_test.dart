import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  // Like the `bat` emoji of the `animated_emoji` package, each layer ends 0.16
  // frame before the next one starts. Frames 20 and 40 used to be blank.
  test('Consecutive layers switch on the exact frame', () async {
    var composition = await LottieComposition.fromBytes(
      utf8.encode(
        jsonEncode({
          'v': '5.7.4',
          'fr': 60,
          'ip': 0,
          'op': 60,
          'w': 10,
          'h': 10,
          'layers': [
            _solid(1, '#0000ff', 40, 59.84),
            _solid(2, '#00ff00', 20, 39.84),
            _solid(3, '#ff0000', 0, 19.84),
          ],
        }),
      ),
    );
    var drawable = LottieDrawable(composition);

    for (var frame = 0; frame < 60; frame++) {
      var expected = switch (frame) {
        < 20 => const Color(0xffff0000),
        < 40 => const Color(0xff00ff00),
        _ => const Color(0xff0000ff),
      };
      expect(
        await _renderCenterPixel(drawable, (frame + 0.5) / 60),
        expected,
        reason: 'frame $frame',
      );
    }
  });
}

Map<String, Object> _solid(int index, String color, num ip, num op) => {
  'ty': 1,
  'ind': index,
  'sw': 10,
  'sh': 10,
  'sc': color,
  'ip': ip,
  'op': op,
  'st': 0,
  'ks': <String, Object>{},
};

Future<Color> _renderCenterPixel(
  LottieDrawable drawable,
  double progress,
) async {
  drawable.setProgress(progress);
  var recorder = PictureRecorder();
  drawable.draw(Canvas(recorder), const Rect.fromLTWH(0, 0, 10, 10));
  var picture = recorder.endRecording();
  var image = await picture.toImage(10, 10);
  var pixels = (await image.toByteData())!;
  image.dispose();
  picture.dispose();

  var offset = (5 * 10 + 5) * 4;
  return Color.fromARGB(
    pixels.getUint8(offset + 3),
    pixels.getUint8(offset),
    pixels.getUint8(offset + 1),
    pixels.getUint8(offset + 2),
  );
}
