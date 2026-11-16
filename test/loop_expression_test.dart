import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/animation/keyframe/base_keyframe_animation.dart';
import 'package:lottie/src/value/lottie_frame_info.dart';
import 'package:lottie/src/value/lottie_value_callback.dart';

const _red = Color(0xffff0000);
const _blue = Color(0xff0000ff);

void main() {
  group('loopOut', () {
    // 0 on the frame 0, 100 on the frame 10, 50 on the frame 20.
    const keyframes = {0: 0, 10: 100, 20: 50};

    test('cycles all the keyframes by default', () {
      for (var expression in [
        'var \$bm_rt;\n\$bm_rt = loopOut();',
        "var \$bm_rt;\n\$bm_rt = loopOut('cycle');",
        "var \$bm_rt;\n\$bm_rt = loopOut('cycle', 0);",
        r"$bm_rt = loopOut('cycle', 5)",
        'loop_out("cycle")',
        "loopOut('')",
      ]) {
        expect(
          _rotation(keyframes, expression, [10, 20, 25, 30, 35, 40, 45, 99]),
          _closeTo([100, 50, 50, 100, 75, 0, 50, 55]),
          reason: expression,
        );
      }
    });

    test('cycles the last keyframes', () {
      expect(
        _rotation(keyframes, "loopOut('cycle', 1)", [20, 25, 30, 35]),
        _closeTo([50, 75, 100, 75]),
      );
    });

    test('ping-pongs', () {
      expect(
        _rotation(keyframes, "loopOut('pingpong')", [20, 25, 30, 35, 40, 45]),
        _closeTo([50, 75, 100, 50, 0, 50]),
      );
      expect(
        _rotation(keyframes, "loopOut('pingpong')", [60, 65]),
        _closeTo([50, 75]),
      );
    });

    test('offsets each cycle by the change over the cycle', () {
      expect(
        _rotation(keyframes, "loopOut('offset')", [20, 25, 30, 40, 45]),
        _closeTo([50, 100, 150, 100, 150]),
      );
    });

    test('continues with the last velocity', () {
      expect(
        _rotation(keyframes, "loopOut('continue')", [20, 25, 30, 40]),
        _closeTo([50, 25, 0, -50]),
      );
    });

    test('continues after an ease without moving', () {
      expect(
        _rotation(
          {0: 0, 10: 100},
          "loopOut('continue')",
          [10, 11, 50],
          ease: true,
        ),
        _closeTo([100, 100, 100]),
      );
    });

    test('continues an opacity before it is rounded', () {
      var opacity = _composition(
        opacity: _property({0: 0, 10: 50}, "loopOut('continue')"),
      ).layers.single.transform.opacity!.createAnimation();
      expect(_values(opacity, [10, 11, 12, 20]), [50, 55, 60, 100]);
    });

    test('offsets a position', () {
      var position = _composition(
        position: _property(const {
          0: [0, 0, 0],
          10: [10, 0, 0],
        }, "loopOut('offset')"),
      ).layers.single.transform.position!.createAnimation();
      expect(
        _values(position, [5, 15, 25]),
        _closeToOffsets(const [Offset(5, 0), Offset(15, 0), Offset(25, 0)]),
      );
    });

    test('continues a position', () {
      var position = _composition(
        position: _property(const {
          0: [0, 0, 0],
          10: [10, 20, 0],
        }, "loopOut('continue')"),
      ).layers.single.transform.position!.createAnimation();
      expect(
        _values(position, [10, 12, 50]),
        _closeToOffsets(const [
          Offset(10, 20),
          Offset(12, 24),
          Offset(50, 100),
        ]),
      );
    });

    test('repeats a last keyframe that follows a hold', () {
      // 0 to 100 until the frame 10, holds 100, and 30 from the frame 15.
      expect(
        _rotation(
          {0: 0, 10: 100, 15: 30},
          'loopOut()',
          [5, 12, 15, 16, 27, 30],
          holds: {10},
        ),
        _closeTo([50, 100, 30, 10, 100, 0]),
      );
    });
  });

  group('loopIn', () {
    // 0 on the frame 20, 100 on the frame 30, 50 on the frame 40.
    const keyframes = {20: 0, 30: 100, 40: 50};

    test('cycles all the keyframes by default', () {
      for (var expression in [
        'var \$bm_rt;\n\$bm_rt = loopIn();',
        "var \$bm_rt;\n\$bm_rt = loopIn('cycle');",
        'loop_in()',
      ]) {
        expect(
          _rotation(keyframes, expression, [0, 5, 10, 15, 20, 30, 50]),
          _closeTo([50, 50, 100, 75, 0, 100, 50]),
          reason: expression,
        );
      }
    });

    test('cycles the first keyframes', () {
      expect(
        _rotation(keyframes, "loopIn('cycle', 1)", [5, 10, 15]),
        _closeTo([50, 100, 50]),
      );
    });

    test('ping-pongs', () {
      // A pre-composition can play the frames before 0.
      expect(
        _rotation(keyframes, "loopIn('pingpong')", [-5, 0, 5, 15]),
        _closeTo([75, 50, 75, 50]),
      );
    });

    test('offsets each cycle by the change over the cycle', () {
      expect(
        _rotation(keyframes, "loopIn('offset')", [0, 5, 15]),
        _closeTo([-50, 0, 25]),
      );
    });

    test('continues with the first velocity', () {
      expect(
        _rotation(keyframes, "loopIn('continue')", [10, 15, 20]),
        _closeTo([-100, -50, 0]),
      );
    });
  });

  group('a time remap', () {
    // The pre-composition is red for 5 frames, then blue for 5 frames.
    const precomp = [
      {'color': '#ff0000', 'inPoint': 0, 'outPoint': 5},
      {'color': '#0000ff', 'inPoint': 5, 'outPoint': 10},
    ];

    test('that loops keeps playing its pre-composition', () async {
      var composition = _composition(
        timeRemap: _property({
          0: 0,
          10: 1,
        }, "var \$bm_rt;\n\$bm_rt = loopOut('cycle', 0);"),
        precomp: precomp,
      );
      expect(composition.warnings, isEmpty);
      expect(await _pixels(composition, [2, 7, 22, 27, 92, 97]), [
        _red,
        _blue,
        _red,
        _blue,
        _red,
        _blue,
      ]);
    });

    test('without the loop stays on its last frame', () async {
      // Stops on the frame 9: a remap past the end of the pre-composition
      // would show nothing, like in lottie-web.
      var composition = _composition(
        timeRemap: _property({0: 0, 10: 0.9}, null),
        precomp: precomp,
      );
      expect(await _pixels(composition, [2, 22, 27]), [_red, _blue, _blue]);
    });
  });

  group('invalidates', () {
    test('a cycle when it changes only', () {
      // Transparent for 10 frames, opaque for 10 frames, and again.
      var changed = _changedFrames(
        _composition(
          opacity: _property(
            {0: 0, 10: 100, 20: 0},
            'loopOut()',
            holds: {0, 10},
          ),
        ),
      );
      expect(changed, containsAll([10, 20, 30, 40, 50, 60, 70, 80, 90]));
      // The frame 21 leaves the last keyframe, which doesn't repeat.
      var holds = {
        for (var frame = 22; frame < 100; frame++)
          if (frame % 10 != 0) frame,
      };
      expect(changed.intersection(holds), isEmpty);
    });

    test('a continued motion on every frame', () {
      var changed = _changedFrames(
        _composition(
          rotation: _property({0: 0, 10: 100}, "loopOut('continue')"),
        ),
      );
      expect(changed, containsAll([for (var i = 1; i < 100; i++) i]));
    });

    test('nothing once a continued motion stopped', () {
      var changed = _changedFrames(
        _composition(
          rotation: _property(
            {0: 0, 10: 100},
            "loopOut('continue')",
            ease: true,
          ),
        ),
      );
      expect(changed.where((frame) => frame > 10), isEmpty);
    });
  });

  group('warns about', () {
    for (var expression in [
      'wiggle(2, 10)',
      "loopOut('cycle') * 2",
      "loopOut('bounce')",
      "loopOutDuration('cycle', 1)",
    ]) {
      test(expression, () {
        var composition = _composition(
          rotation: _property(const {0: 0, 10: 100}, expression),
        );
        expect(composition.warnings, ["Lottie doesn't support expressions."]);
      });
    }

    test('a position expression', () {
      var composition = _composition(
        position: _property(const {
          0: [0, 0, 0],
          10: [10, 0, 0],
        }, 'wiggle(2, 10)'),
      );
      expect(composition.warnings, ["Lottie doesn't support expressions."]);
    });

    test('an offset loop on a color', () {
      var composition = _composition(
        shapes: [
          _rectangle,
          {
            'ty': 'fl',
            'c': _property(const {
              0: [1, 0, 0, 1],
              10: [0, 0, 1, 1],
            }, "loopOut('offset')"),
            'o': {'a': 0, 'k': 100},
          },
        ],
      );
      expect(composition.warnings, ["Lottie doesn't support expressions."]);
    });
  });

  group('with a value callback', () {
    test('a relative one follows an offset loop', () {
      var rotation = _rotationAnimation({0: 0, 10: 100}, "loopOut('offset')")
        ..setValueCallback(
          LottieValueCallback<double>(null)
            ..callback = (LottieFrameInfo<double> info) =>
                info.startValue! +
                (info.endValue! - info.startValue!) *
                    info.interpolatedKeyframeProgress +
                10,
        );
      expect(_values(rotation, [5, 15, 25]), _closeTo([60, 160, 260]));
    });

    test('an absolute one is not moved by an offset loop', () {
      var rotation = _rotationAnimation({0: 0, 10: 100}, "loopOut('offset')")
        ..setValueCallback(LottieValueCallback<double>(45));
      expect(_values(rotation, [5, 15, 25]), _closeTo([45, 45, 45]));
    });

    test('one that gives no value leaves the loop', () {
      var rotation = _rotationAnimation({0: 0, 10: 100}, "loopOut('offset')")
        ..setValueCallback(LottieValueCallback<double>(null));
      expect(_values(rotation, [5, 15, 25]), _closeTo([50, 150, 250]));
    });
  });

  test('loopIn continues before an ease without moving', () {
    expect(
      _rotation(
        {20: 0, 30: 100},
        "loopIn('continue')",
        [0, 19, 20],
        ease: true,
      ),
      _closeTo([0, 0, 0]),
    );
  });

  test('an anchor point loops', () {
    var anchor = _composition(
      anchor: _property(const {
        0: [0, 0, 0],
        10: [10, 0, 0],
      }, 'loopOut()'),
    ).layers.single.transform.anchorPoint!.createAnimation();
    expect(
      _values(anchor, [5, 15]),
      _closeToOffsets(const [Offset(5, 0), Offset(5, 0)]),
    );
  });

  test('an anchor point whose expression is not a string loads', () {
    for (var expression in [null, 5, <String, Object>{}]) {
      var composition = _composition(
        anchor: {
          'a': 0,
          'k': [1, 2, 0],
          'x': expression,
        },
      );
      expect(
        composition
            .layers
            .single
            .transform
            .anchorPoint!
            .keyframes
            .single
            .startValue,
        const Offset(1, 2),
      );
    }
  });

  group('an opacity that loops out of range', () {
    test('is clamped on a layer', () async {
      // 50% then 150% opacity on the next cycle, over a 50% fill.
      var composition = _composition(
        opacity: _property({0: 0, 10: 100}, "loopOut('offset')"),
        shapes: [
          _rectangle,
          {
            ..._redFill,
            'o': const {'a': 0, 'k': 50},
          },
        ],
      );
      var alpha = (await _pixels(composition, [15])).single.a;
      expect(alpha, closeTo(0.5, 0.01));
    });

    test('is clamped on a mask', () async {
      var composition = _composition(
        maskOpacity: _property({0: 0, 10: 100}, "loopOut('offset')"),
      );
      expect(await _pixels(composition, [15]), [_red]);
    });
  });

  test('a jump across repetitions invalidates', () {
    // Opaque for 18 frames, transparent for 2, and again: a jump from the
    // frame 37 to the frame 41 goes through transparent frames.
    var composition = _composition(
      opacity: _property({0: 100, 18: 0, 20: 100}, 'loopOut()', holds: {0, 18}),
    );
    var drawable = LottieDrawable(composition);
    for (var frame = 0; frame <= 37; frame++) {
      drawable.setProgress(frame / composition.durationFrames);
    }
    expect(drawable.setProgress(41 / composition.durationFrames), isTrue);
  });

  test('auto-orient follows a looping position across its seams', () {
    // Moves right from (0, 0) to (10, 0) every 10 frames.
    var transform = _composition(
      position: _property(const {
        0: [0, 0, 0],
        10: [10, 0, 0],
      }, 'loopOut()'),
      autoOrient: true,
    ).layers.single.transform.createAnimation();
    for (var frame in [5, 10, 11, 19, 20, 21]) {
      transform.setProgress(frame / _durationFrames);
      var matrix = transform.getMatrix();
      expect(matrix.entry(0, 0), closeTo(1, 1e-6), reason: 'frame $frame');
    }
  });

  test('a long expression is read in linear time', () {
    var composition = _composition(
      rotation: _property(const {0: 0, 10: 100}, 'loopOut()${' ' * 300000}x'),
    );
    expect(composition.warnings, ["Lottie doesn't support expressions."]);
  });

  test('a loop on a single keyframe keeps it', () {
    for (var type in ['cycle', 'continue']) {
      expect(
        _rotation({10: 45}, "loopOut('$type')", [0, 50]),
        _closeTo([45, 45]),
      );
    }
  });

  test('a loop on a value that is not animated keeps it', () {
    var composition = _composition(
      rotation: {'a': 0, 'k': 45, 'x': 'loopOut()'},
    );
    expect(composition.warnings, isEmpty);
    var rotation = composition.layers.single.transform.rotation!
        .createAnimation();
    expect(_values(rotation, [0, 50]), [45, 45]);
  });
}

/// The frames of [_composition], once its 0.01 is removed.
const _durationFrames = 99.99;

/// The value of [animation] on each of [frames].
List<Object?> _values(
  BaseKeyframeAnimation<Object, Object?> animation,
  List<num> frames,
) => [
  for (var frame in frames)
    (animation..setProgress(frame / _durationFrames)).value,
];

/// The rotation going through [keyframes] with [expression], on each of
/// [frames].
List<Object?> _rotation(
  Map<num, num> keyframes,
  String expression,
  List<num> frames, {
  Set<num> holds = const {},
  bool ease = false,
}) {
  return _values(
    _rotationAnimation(keyframes, expression, holds: holds, ease: ease),
    frames,
  );
}

/// The animation of a rotation going through [keyframes] with [expression].
BaseKeyframeAnimation<double, double> _rotationAnimation(
  Map<num, num> keyframes,
  String expression, {
  Set<num> holds = const {},
  bool ease = false,
}) {
  var composition = _composition(
    rotation: _property(keyframes, expression, holds: holds, ease: ease),
  );
  expect(composition.warnings, isEmpty, reason: expression);
  return composition.layers.single.transform.rotation!.createAnimation();
}

List<Matcher> _closeTo(List<num> values) => [
  for (var value in values) closeTo(value, 1e-6),
];

/// Paths are measured in floats.
List<Matcher> _closeToOffsets(List<Offset> values) => [
  for (var value in values)
    isA<Offset>()
        .having((offset) => offset.dx, 'dx', closeTo(value.dx, 1e-2))
        .having((offset) => offset.dy, 'dy', closeTo(value.dy, 1e-2)),
];

/// The frames [composition] is repainted on, played from the start.
Set<int> _changedFrames(LottieComposition composition) {
  var drawable = LottieDrawable(composition)..setProgress(0);
  return {
    for (var frame = 1; frame < 100; frame++)
      if (drawable.setProgress(frame / composition.durationFrames)) frame,
  };
}

/// An animated property going through [keyframes] linearly, or eased in and
/// out with [ease], with the [expression] Bodymovin exports in "x". The
/// keyframes on [holds] hold their value.
Map<String, Object?> _property(
  Map<num, Object> keyframes,
  String? expression, {
  Set<num> holds = const {},
  bool ease = false,
}) {
  var (easeOut, easeIn) = ease ? (0.4, 0.6) : (0.0, 1.0);
  return {
    'a': 1,
    'k': [
      for (var MapEntry(key: frame, value: value) in keyframes.entries)
        {
          't': frame,
          's': value is List ? value : [value],
          if (holds.contains(frame)) 'h': 1,
          'o': {
            'x': [easeOut],
            'y': [0],
          },
          'i': {
            'x': [easeIn],
            'y': [1],
          },
        },
    ],
    'x': ?expression,
  };
}

/// A composition of 10x10 pixels and 100 frames at 10 fps. Its layer is a
/// shape layer with the given transform and [shapes], or a pre-composition of
/// the solids of [precomp], whose time is remapped by [timeRemap].
LottieComposition _composition({
  Map<String, Object?>? opacity,
  Map<String, Object?>? rotation,
  Map<String, Object?>? position,
  Map<String, Object?>? anchor,
  bool autoOrient = false,
  Map<String, Object?>? maskOpacity,
  Map<String, Object?>? timeRemap,
  List<Map<String, Object>> precomp = const [],
  List<Map<String, Object?>> shapes = const [_rectangle, _redFill],
}) {
  var layer = {
    'ind': 1,
    'ip': 0,
    'op': 100,
    'st': 0,
    'ao': autoOrient ? 1 : 0,
    'ks': {'o': ?opacity, 'r': ?rotation, 'p': ?position, 'a': ?anchor},
    if (maskOpacity != null)
      'masksProperties': [
        {
          'mode': 'a',
          'inv': false,
          'o': maskOpacity,
          'pt': {
            'a': 0,
            'k': {
              'c': true,
              'v': [
                [0, 0],
                [10, 0],
                [10, 10],
                [0, 10],
              ],
              'i': [
                [0, 0],
                [0, 0],
                [0, 0],
                [0, 0],
              ],
              'o': [
                [0, 0],
                [0, 0],
                [0, 0],
                [0, 0],
              ],
            },
          },
        },
      ],
  };
  return LottieComposition.parseJsonBytes(
    utf8.encode(
      jsonEncode({
        'v': '5.7.4',
        'fr': 10,
        'ip': 0,
        'op': 100,
        'w': 10,
        'h': 10,
        'assets': [
          if (precomp.isNotEmpty)
            {
              'id': 'comp_0',
              'layers': [
                for (var solid in precomp)
                  {
                    'ty': 1,
                    'ind': 1,
                    'sw': 10,
                    'sh': 10,
                    'sc': solid['color'],
                    'ip': solid['inPoint'],
                    'op': solid['outPoint'],
                    'st': 0,
                    'ks': <String, Object>{},
                  },
              ],
            },
        ],
        'layers': [
          if (precomp.isNotEmpty)
            {
              ...layer,
              'ty': 0,
              'refId': 'comp_0',
              'w': 10,
              'h': 10,
              'tm': ?timeRemap,
            }
          else
            {...layer, 'ty': 4, 'shapes': shapes},
        ],
      }),
    ),
  );
}

/// An opaque red fill.
const Map<String, Object?> _redFill = {
  'ty': 'fl',
  'c': {
    'a': 0,
    'k': [1, 0, 0, 1],
  },
  'o': {'a': 0, 'k': 100},
};

/// A rectangle covering the composition, to fill.
const Map<String, Object?> _rectangle = {
  'ty': 'rc',
  'd': 1,
  's': {
    'a': 0,
    'k': [10, 10],
  },
  'p': {
    'a': 0,
    'k': [5, 5],
  },
  'r': {'a': 0, 'k': 0},
};

/// The center pixel of [composition] on each of [frames].
Future<List<Color>> _pixels(
  LottieComposition composition,
  List<int> frames,
) async {
  var colors = <Color>[];
  for (var frame in frames) {
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
    colors.add(
      Color.fromARGB(
        pixels.getUint8(offset + 3),
        pixels.getUint8(offset),
        pixels.getUint8(offset + 1),
        pixels.getUint8(offset + 2),
      ),
    );
  }
  return colors;
}
