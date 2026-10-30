import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const _transparent = Color(0x00000000);
const _red = Color(0xffff0000);

void main() {
  // The frame 113 of the root is the frame 55 of the precomp. Its progress
  // fell one ulp between the keyframes [52, 55) and [55, 60), and the lookup
  // fell back to the first keyframe (#459).
  test('a precomp frame on a keyframe boundary starts that keyframe', () {
    var composition = _composition(
      frameRate: 60,
      outPoint: 286,
      layers: [_precomp(outPoint: 286, startFrame: 58)],
      precomp: [
        _box(
          outPoint: 286,
          rotationKeyframes: [29, 33, 35, 42, 49, 52, 55, 60],
        ),
      ],
    );
    expect(_keyframeStarts(composition, ['pre', 'box'], from: 110, to: 114), {
      110: 52,
      111: 52,
      112: 52,
      113: 55,
      114: 55,
    });
  });

  // 24.99 / 24 * 24 is not 24.99: the progress of the frame 15 fell between
  // the keyframes [14, 15) and [15, 20) at the root too.
  test('a root frame on a keyframe boundary starts that keyframe', () {
    var composition = _composition(
      frameRate: 24,
      outPoint: 25,
      layers: [
        _box(outPoint: 25, rotationKeyframes: [10, 14, 15, 20]),
      ],
    );
    expect(_keyframeStarts(composition, ['box'], from: 13, to: 16), {
      13: 10,
      14: 14,
      15: 15,
      16: 15,
    });
  });

  // The precomp starts on the frame 1, so its frame 7 is the frame 8 of the
  // root. The progress handed to the precomp used to be one ulp short of it.
  test('a hold keyframe in a precomp changes on its frame', () async {
    var composition = _composition(
      frameRate: 60,
      outPoint: 60,
      layers: [_precomp(outPoint: 60, startFrame: 1)],
      precomp: [_solid(outPoint: 60, opacity: _holdUntil(7))],
    );
    expect(await _pixel(composition, 7), _transparent);
    expect(await _pixel(composition, 8), _red);
  });

  test('a layer in a precomp appears on its in point', () async {
    var composition = _composition(
      frameRate: 60,
      outPoint: 60,
      layers: [_precomp(outPoint: 60, startFrame: 1)],
      precomp: [_solid(inPoint: 7, outPoint: 60)],
    );
    expect(await _pixel(composition, 7), _transparent);
    expect(await _pixel(composition, 8), _red);
  });

  // Stretched 3 times, the precomp shows its frame 11 on the frame 33.
  test('a stretched precomp changes on its frame', () async {
    var composition = _composition(
      frameRate: 60,
      outPoint: 60,
      layers: [_precomp(outPoint: 60, stretch: 3)],
      precomp: [_solid(outPoint: 60, opacity: _holdUntil(11))],
    );
    expect(await _pixel(composition, 32), _transparent);
    expect(await _pixel(composition, 33), _red);
  });
}

/// A 10x10 composition starting on the frame 0.
LottieComposition _composition({
  required num frameRate,
  required num outPoint,
  required List<Map<String, Object?>> layers,
  List<Map<String, Object?>> precomp = const [],
}) {
  return LottieComposition.parseJsonBytes(
    utf8.encode(
      jsonEncode({
        'v': '5.7.4',
        'fr': frameRate,
        'ip': 0,
        'op': outPoint,
        'w': 10,
        'h': 10,
        'assets': [
          if (precomp.isNotEmpty) {'id': 'comp_0', 'layers': precomp},
        ],
        'layers': layers,
      }),
    ),
  );
}

Map<String, Object?> _precomp({
  required num outPoint,
  num startFrame = 0,
  num stretch = 1,
}) => {
  'ty': 0,
  'ind': 1,
  'nm': 'pre',
  'refId': 'comp_0',
  'ip': 0,
  'op': outPoint,
  'st': startFrame,
  'sr': stretch,
  'w': 10,
  'h': 10,
  'ks': <String, Object>{},
};

/// A 10x10 red solid.
Map<String, Object?> _solid({
  required num outPoint,
  num inPoint = 0,
  Map<String, Object?>? opacity,
}) => {
  'ty': 1,
  'ind': 1,
  'nm': 'solid',
  'sw': 10,
  'sh': 10,
  'sc': '#ff0000',
  'ip': inPoint,
  'op': outPoint,
  'st': 0,
  'ks': {'o': ?opacity},
};

/// Transparent, then opaque from [frame].
Map<String, Object?> _holdUntil(num frame) => {
  'a': 1,
  'k': [
    {
      't': 0,
      's': [0],
      'h': 1,
    },
    {
      't': frame,
      's': [100],
    },
  ],
};

/// A square rotating linearly by 10 degrees per keyframe.
Map<String, Object?> _box({
  required num outPoint,
  required List<num> rotationKeyframes,
}) => {
  'ty': 4,
  'ind': 1,
  'nm': 'box',
  'ip': 0,
  'op': outPoint,
  'st': 0,
  'ks': {
    'r': {
      'a': 1,
      'k': [
        for (var (i, t) in rotationKeyframes.indexed)
          {
            't': t,
            's': [10 * (i + 1)],
            'o': {
              'x': [0],
              'y': [0],
            },
            'i': {
              'x': [1],
              'y': [1],
            },
          },
      ],
    },
    'p': {
      'a': 0,
      'k': [5, 5, 0],
    },
  },
  'shapes': [
    {
      'ty': 'rc',
      'd': 1,
      's': {
        'a': 0,
        'k': [4, 4],
      },
      'p': {
        'a': 0,
        'k': [0, 0],
      },
      'r': {'a': 0, 'k': 0},
    },
    {
      'ty': 'fl',
      'c': {
        'a': 0,
        'k': [1, 0, 0, 1],
      },
      'o': {'a': 0, 'k': 100},
      'r': 1,
    },
  ],
};

/// The start frame of the rotation keyframe in effect on each frame of
/// [from]..[to], drawn in order like an animation: the lookup starts from the
/// previous frame's keyframe.
Map<int, double?> _keyframeStarts(
  LottieComposition composition,
  List<String> keyPath, {
  required int from,
  required int to,
}) {
  double? startFrame;
  var drawable = LottieDrawable(composition)
    ..delegates = LottieDelegates(
      values: [
        ValueDelegate.transformRotation(
          keyPath,
          callback: (info) {
            startFrame = info.startFrame;
            return info.startValue! +
                (info.endValue! - info.startValue!) *
                    info.interpolatedKeyframeProgress;
          },
        ),
      ],
    );
  var starts = <int, double?>{};
  for (var frame = from; frame <= to; frame++) {
    drawable.setProgress(frame / composition.durationFrames);
    drawable.draw(Canvas(PictureRecorder()), const Rect.fromLTWH(0, 0, 10, 10));
    starts[frame] = startFrame;
  }
  return starts;
}

/// The center pixel of [composition] on [frame].
Future<Color> _pixel(LottieComposition composition, int frame) async {
  var drawable = LottieDrawable(composition)
    ..setProgress(frame / composition.durationFrames);
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
