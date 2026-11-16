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

  group('a remapped frame', () {
    test(
      'closing a trimmed round-cap stroke on a keyframe draws nothing',
      () async {
        // The remap plays the pre-composition at its own pace. The trim start
        // reaches the end of the line on the frame 18, where nothing is left to
        // draw: a frame played a hair early would leave a round-cap dot.
        var composition = _remappedComposition(
          frameRate: 30,
          outFrame: 30,
          timeRemap: _linear(0, 0, 30, 1),
          precompLayers: [_trimmedLine],
        );
        expect(await _pixel(composition, 17, 90, 50), _red);
        expect(await _pixel(composition, 18, 90, 50), _transparent);
        expect(await _pixel(composition, 19, 90, 50), _transparent);
      },
    );

    // Red for 5 frames, then blue for 5 frames.
    final redThenBlue = [_solid('#ff0000', 0, 5), _solid('#0000ff', 5, 10)];

    test('on the layer out point shows the frame before it', () async {
      // The remap reaches 1 s, the frame 10, on the frame 5.
      var composition = _remappedComposition(
        frameRate: 10,
        outFrame: 10,
        timeRemap: _linear(0, 0, 5, 1),
        precompLayers: redThenBlue,
      );
      expect(await _pixel(composition, 2, 5, 5), _red);
      expect(await _pixel(composition, 7, 5, 5), _blue);
    });

    test('past the end of the pre-composition shows nothing', () async {
      // As above, but the layer lasts beyond the frame 10.
      var composition = _remappedComposition(
        frameRate: 10,
        outFrame: 20,
        timeRemap: _linear(0, 0, 5, 1),
        precompLayers: redThenBlue,
      );
      expect(await _pixel(composition, 2, 5, 5), _red);
      expect(await _pixel(composition, 7, 5, 5), _transparent);
    });
  });
}

const _red = Color(0xffff0000);
const _blue = Color(0xff0000ff);
const _transparent = Color(0x00000000);

const _transform = {
  'o': {'a': 0, 'k': 100},
  'r': {'a': 0, 'k': 0},
  'p': {
    'a': 0,
    'k': [0, 0, 0],
  },
  'a': {
    'a': 0,
    'k': [0, 0, 0],
  },
  's': {
    'a': 0,
    'k': [100, 100, 100],
  },
};

/// A 100x100 composition, the size of [precompLayers], showing them through a
/// pre-composition layer from the frame 0 to [outFrame] with [timeRemap].
LottieComposition _remappedComposition({
  required int frameRate,
  required int outFrame,
  required Map<String, Object> timeRemap,
  required List<Map<String, Object>> precompLayers,
}) {
  return LottieComposition.parseJsonBytes(
    utf8.encode(
      jsonEncode({
        'v': '5.7.4',
        'fr': frameRate,
        'ip': 0,
        'op': outFrame,
        'w': 100,
        'h': 100,
        'assets': [
          {'id': 'precomp', 'layers': precompLayers},
        ],
        'layers': [
          {
            'ty': 0,
            'ind': 1,
            'refId': 'precomp',
            'w': 100,
            'h': 100,
            'ip': 0,
            'op': outFrame,
            'st': 0,
            'sr': 1,
            'tm': timeRemap,
            'ks': _transform,
          },
        ],
      }),
    ),
  );
}

/// A time remap from [startValue] seconds on [startFrame] to [endValue] on
/// [endFrame], linearly.
Map<String, Object> _linear(
  int startFrame,
  double startValue,
  int endFrame,
  double endValue,
) {
  return {
    'a': 1,
    'k': [
      {
        't': startFrame,
        's': [startValue],
        'e': [endValue],
        'i': {
          'x': [1],
          'y': [1],
        },
        'o': {
          'x': [0],
          'y': [0],
        },
      },
      {'t': endFrame},
    ],
  };
}

Map<String, Object> _solid(String color, int inFrame, int outFrame) {
  return {
    'ty': 1,
    'ind': 1,
    'sw': 100,
    'sh': 100,
    'sc': color,
    'ip': inFrame,
    'op': outFrame,
    'st': 0,
    'sr': 1,
    'ks': _transform,
  };
}

/// A red line from (10, 50) to (90, 50), 20 wide with round caps, whose trim
/// start goes from 0% on the frame 6 to 100% on the frame 18, like a flame of
/// the LottieFiles "Rocket" animation.
const Map<String, Object> _trimmedLine = {
  'ty': 4,
  'ind': 1,
  'ip': 0,
  'op': 30,
  'st': 0,
  'sr': 1,
  'ks': _transform,
  'shapes': [
    {
      'ty': 'sh',
      'ks': {
        'a': 0,
        'k': {
          'c': false,
          'v': [
            [10, 50],
            [90, 50],
          ],
          'i': [
            [0, 0],
            [0, 0],
          ],
          'o': [
            [0, 0],
            [0, 0],
          ],
        },
      },
    },
    {
      'ty': 'tm',
      's': {
        'a': 1,
        'k': [
          {
            't': 6,
            's': [0],
            'e': [100],
            'i': {
              'x': [1],
              'y': [1],
            },
            'o': {
              'x': [0],
              'y': [0],
            },
          },
          {'t': 18},
        ],
      },
      'e': {'a': 0, 'k': 100},
      'o': {'a': 0, 'k': 0},
      'm': 1,
    },
    {
      'ty': 'st',
      'c': {
        'a': 0,
        'k': [1, 0, 0, 1],
      },
      'o': {'a': 0, 'k': 100},
      'w': {'a': 0, 'k': 20},
      'lc': 2,
      'lj': 2,
    },
  ],
};

/// The pixel at ([x], [y]) of [composition] on the [frame].
Future<Color> _pixel(
  LottieComposition composition,
  int frame,
  int x,
  int y,
) async {
  var size = composition.bounds;
  var drawable = LottieDrawable(composition)
    ..setProgress(frame / composition.durationFrames);
  var recorder = PictureRecorder();
  drawable.draw(
    Canvas(recorder),
    Rect.fromLTWH(0, 0, size.width.toDouble(), size.height.toDouble()),
  );
  var picture = recorder.endRecording();
  var image = await picture.toImage(size.width, size.height);
  var pixels = (await image.toByteData())!;
  image.dispose();
  picture.dispose();
  var offset = (y * size.width + x) * 4;
  return Color.fromARGB(
    pixels.getUint8(offset + 3),
    pixels.getUint8(offset),
    pixels.getUint8(offset + 1),
    pixels.getUint8(offset + 2),
  );
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
