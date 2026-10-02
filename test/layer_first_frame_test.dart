import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// A layer that starts exactly on a frame must be visible on that frame.
/// The first layer ends before frame 20 and the second one starts on frame 20,
/// so nothing else is drawn when frame 20 is skipped.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> solid(int index, String color, num ip, num op) => {
    'ddd': 0,
    'ind': index,
    'ty': 1,
    'nm': 'Layer $index',
    'sw': 100,
    'sh': 100,
    'sc': color,
    'ks': {
      'o': {'a': 0, 'k': 100},
      'r': {'a': 0, 'k': 0},
      'p': {
        'a': 0,
        'k': [50, 50, 0],
      },
      'a': {
        'a': 0,
        'k': [50, 50, 0],
      },
      's': {
        'a': 0,
        'k': [100, 100, 100],
      },
    },
    'ip': ip,
    'op': op,
    'st': 0,
    'bm': 0,
  };

  Future<LottieComposition> load(List<Map<String, dynamic>> layers) {
    return LottieComposition.fromBytes(
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'v': '5.8.1',
            'fr': 60,
            'ip': 0,
            'op': 60,
            'w': 100,
            'h': 100,
            'nm': 'Frame boundaries',
            'ddd': 0,
            'assets': <Object>[],
            'layers': layers,
          }),
        ),
      ),
    );
  }

  Future<ByteData> render(LottieDrawable drawable, double progress) async {
    drawable.setProgress(progress);
    var recorder = ui.PictureRecorder();
    drawable.draw(ui.Canvas(recorder), const ui.Rect.fromLTWH(0, 0, 100, 100));
    var image = await recorder.endRecording().toImage(100, 100);
    var data = (await image.toByteData())!;
    image.dispose();
    return data;
  }

  Future<bool> isBlank(LottieDrawable drawable, double progress) async {
    var data = await render(drawable, progress);
    for (var i = 3; i < data.lengthInBytes; i += 4) {
      if (data.getUint8(i) != 0) return false;
    }
    return true;
  }

  /// The color of the center pixel, as 0xAARRGGBB.
  Future<int> centerColor(LottieDrawable drawable, double progress) async {
    var data = await render(drawable, progress);
    var offset = (50 * 100 + 50) * 4;
    return (data.getUint8(offset + 3) << 24) |
        (data.getUint8(offset) << 16) |
        (data.getUint8(offset + 1) << 8) |
        data.getUint8(offset + 2);
  }

  test(
    'A layer starting exactly on a frame is visible on that frame',
    () async {
      var composition = await load([
        solid(1, '#00ff00', 20, 39.84),
        solid(2, '#ff0000', 0, 19.84),
      ]);
      var drawable = LottieDrawable(composition);
      var frameCount = (composition.durationFrames + 0.01).round();

      for (var frame = 0; frame < 40; frame++) {
        var progress = (frame + 0.5) / frameCount;
        expect(
          await isBlank(drawable, progress),
          isFalse,
          reason: 'frame $frame',
        );
      }
      expect(await isBlank(drawable, 40.5 / frameCount), isTrue);
    },
  );

  // Animated emojis such as the `bat` of the `animated_emoji` package are made
  // of consecutive layers that end 0.16 frame before the next one starts
  // (0-19.84, 20-39.84, 40-59.84). Frames 20 and 40 used to be blank.
  test(
    'Consecutive layers are never blank and switch on the exact frame',
    () async {
      var composition = await load([
        solid(1, '#0000ff', 40, 59.84),
        solid(2, '#00ff00', 20, 39.84),
        solid(3, '#ff0000', 0, 19.84),
      ]);
      var drawable = LottieDrawable(composition);
      var frameCount = (composition.durationFrames + 0.01).round();
      expect(frameCount, 60);

      for (var frame = 0; frame < frameCount; frame++) {
        var expected = switch (frame) {
          < 20 => 0xFFFF0000,
          < 40 => 0xFF00FF00,
          _ => 0xFF0000FF,
        };
        expect(
          await centerColor(drawable, (frame + 0.5) / frameCount),
          expected,
          reason: 'frame $frame',
        );
      }
    },
  );
}
