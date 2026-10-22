import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// A pause exported as a regular eased keyframe: same value at both ends.
const _ease = '"o": {"x": 0.4, "y": 0}, "i": {"x": 0.6, "y": 1}';
const _linear = '"o": {"x": 0, "y": 0}, "i": {"x": 1, "y": 1}';

/// Waits (eased keyframe between equal values) until frame 30, moves right
/// until 60, waits (hold keyframe) until 90, moves back until 120.
const _pausesAndMoves =
    '''
  {"t": 0, "s": [10, 5], $_ease},
  {"t": 30, "s": [10, 5], $_ease},
  {"t": 60, "s": [40, 5], "h": 1},
  {"t": 90, "s": [40, 5], $_ease},
  {"t": 120, "s": [10, 5]}
''';

/// A 10x10 red square in a 60x30 composition of 120 frames.
Future<LottieComposition> _load({
  required String position,
  bool autoOrient = false,
}) {
  return LottieComposition.fromBytes(
    utf8.encode('''
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 120,
  "w": 60,
  "h": 30,
  "layers": [
    {
      "ty": 1,
      "ind": 1,
      "nm": "Square",
      "sw": 10,
      "sh": 10,
      "sc": "#ff0000",
      "ip": 0,
      "op": 121,
      "st": 0,
      "sr": 1,
      "ao": ${autoOrient ? 1 : 0},
      "ks": {
        "o": {"a": 0, "k": 100},
        "r": {"a": 0, "k": 0},
        "p": {"a": 1, "k": [$position]},
        "a": {"a": 0, "k": [0, 0, 0]},
        "s": {"a": 0, "k": [100, 100, 100]}
      }
    }
  ]
}
'''),
  );
}

/// Moves [drawable] to [frame] and returns whether it has to be repainted.
bool _setFrame(LottieDrawable drawable, int frame) {
  return drawable.setProgress((frame + 0.5) / 120);
}

Future<Uint8List> _render(LottieDrawable drawable) async {
  var recorder = PictureRecorder();
  drawable.draw(Canvas(recorder), Offset.zero & drawable.size);
  var picture = recorder.endRecording();
  var image = await picture.toImage(
    drawable.size.width.round(),
    drawable.size.height.round(),
  );
  var pixels = await image.toByteData();
  image.dispose();
  picture.dispose();
  return pixels!.buffer.asUint8List();
}

int _alphaAt(Uint8List pixels, int x, int y) => pixels[(y * 60 + x) * 4 + 3];

void main() {
  test('a keyframe between equal values does not invalidate', () async {
    var composition = await _load(position: _pausesAndMoves);
    var drawable = LottieDrawable(composition);

    _setFrame(drawable, 0);
    var changed = {
      for (var frame = 1; frame < 120; frame++)
        if (_setFrame(drawable, frame)) frame,
    };

    // Entering the keyframe of a move counts as a change, although it starts
    // from the paused value: frames 30 and 90 are in neither set.
    var pauses = {
      for (var i = 1; i < 30; i++) i,
      for (var i = 61; i < 90; i++) i,
    };
    var moves = {
      for (var i = 31; i <= 60; i++) i,
      for (var i = 91; i < 120; i++) i,
    };
    expect(changed.intersection(pauses), isEmpty);
    expect(changed, containsAll(moves));
  });

  test('an unchanged frame is drawn like the previous one', () async {
    var composition = await _load(position: _pausesAndMoves);
    var drawable = LottieDrawable(composition);

    _setFrame(drawable, 0);
    var previous = await _render(drawable);
    var distinctFrames = 1;
    for (var frame = 1; frame < 120; frame++) {
      var changed = _setFrame(drawable, frame);
      var pixels = await _render(drawable);
      if (changed) {
        distinctFrames++;
      } else {
        expect(pixels, previous, reason: 'frame $frame');
      }
      previous = pixels;
    }
    expect(distinctFrames, lessThan(70));
  });

  test('a position starting with a pause follows its spatial path', () async {
    // The move from (10, 5) to (50, 5) bulges down to y = 14 at mid-course.
    var composition = await _load(
      position:
          '''
  {"t": 0, "s": [10, 5], $_ease},
  {"t": 30, "s": [10, 5], "to": [0, 12], "ti": [0, 12], $_linear},
  {"t": 60, "s": [50, 5]}
''',
    );
    var drawable = LottieDrawable(composition);

    _setFrame(drawable, 45);
    var pixels = await _render(drawable);

    expect(_alphaAt(pixels, 35, 8), 0);
    expect(_alphaAt(pixels, 35, 20), 255);
  });

  test('a value callback still invalidates between equal values', () async {
    var composition = await _load(position: _pausesAndMoves);
    var drawable = LottieDrawable(composition)
      ..delegates = LottieDelegates(
        values: [
          ValueDelegate.transformPosition(
            ['Square'],
            callback: (frameInfo) => Offset(50 * frameInfo.overallProgress, 5),
          ),
        ],
      );

    _setFrame(drawable, 0);
    for (var frame = 1; frame <= 30; frame++) {
      expect(_setFrame(drawable, frame), isTrue, reason: 'frame $frame');
    }
  });

  test('an auto-oriented position invalidates inside a pause', () async {
    // The rotation of an auto-oriented layer comes from the position slightly
    // ahead of the current progress, which can be in the next keyframe.
    var composition = await _load(position: _pausesAndMoves, autoOrient: true);
    var drawable = LottieDrawable(composition);

    _setFrame(drawable, 0);
    for (var frame = 1; frame <= 30; frame++) {
      expect(_setFrame(drawable, frame), isTrue, reason: 'frame $frame');
    }
  });

  for (var (name, size) in const [
    ('is not animated', '{"a": 0, "k": [40, 40]}'),
    (
      'holds',
      '{"a": 1, "k": [{"t": 0, "s": [40, 40], "h": 1}, {"t": 120, "s": [40, 40]}]}',
    ),
  ]) {
    test(
      'a rectangle follows its round corners while its size $name',
      () async {
        var composition = await _loadRoundedRectangle(size: size);
        var drawable = LottieDrawable(composition);

        _setFrame(drawable, 0);
        expect(_alphaAt(await _render(drawable), 11, 11), 255);

        for (var frame = 1; frame <= 60; frame++) {
          _setFrame(drawable, frame);
        }
        var fresh = LottieDrawable(composition);
        _setFrame(fresh, 60);
        var pixels = await _render(drawable);
        expect(pixels, await _render(fresh));
        expect(_alphaAt(pixels, 11, 11), 0);
      },
    );
  }
}

/// A 40x40 red rectangle in a 60x60 composition of 120 frames, whose corners
/// are rounded from 0 to 20 during the first 60 frames.
Future<LottieComposition> _loadRoundedRectangle({required String size}) {
  return LottieComposition.fromBytes(
    utf8.encode('''
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 120,
  "w": 60,
  "h": 60,
  "layers": [
    {
      "ty": 4,
      "ind": 1,
      "nm": "Rectangle",
      "ip": 0,
      "op": 121,
      "st": 0,
      "sr": 1,
      "ks": {
        "o": {"a": 0, "k": 100},
        "r": {"a": 0, "k": 0},
        "p": {"a": 0, "k": [30, 30, 0]},
        "a": {"a": 0, "k": [0, 0, 0]},
        "s": {"a": 0, "k": [100, 100, 100]}
      },
      "shapes": [
        {
          "ty": "rc",
          "d": 1,
          "s": $size,
          "p": {"a": 0, "k": [0, 0]},
          "r": {"a": 0, "k": 0}
        },
        {
          "ty": "rd",
          "r": {"a": 1, "k": [{"t": 0, "s": [0], $_linear}, {"t": 60, "s": [20]}]}
        },
        {
          "ty": "fl",
          "c": {"a": 0, "k": [1, 0, 0, 1]},
          "o": {"a": 0, "k": 100},
          "r": 1
        }
      ]
    }
  ]
}
'''),
  );
}
