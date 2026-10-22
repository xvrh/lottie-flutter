import 'dart:convert';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const _transparent = Color(0x00000000);
const _red = Color(0xffff0000);
const _green = Color(0xff00ff00);

const _holdThenTerminal =
    '{"a": 1, "k": [{"t": 0, "s": [0], "h": 1}, {"t": 10, "s": [100]}]}';

void main() {
  test('a terminal keyframe changes the value after a hold', () async {
    var composition = _solid(opacity: _holdThenTerminal);
    expect(await _pixel(composition, 0.25, 5, 5), _transparent);
    expect(await _pixel(composition, 0.75, 5, 5), _red);
  });

  test('a terminal keyframe moves the layer after a held position', () async {
    var composition = _solid(
      position:
          '{"a": 1, "k": [{"t": 0, "s": [0, 0, 0], "h": 1}, '
          '{"t": 10, "s": [20, 0, 0], "to": [0, 0, 0], "ti": [0, 0, 0]}]}',
    );
    expect(await _pixel(composition, 0.25, 5, 5), _red);
    expect(await _pixel(composition, 0.75, 5, 5), _transparent);
  });

  test('a hold keyframe does not invalidate until the next keyframe', () async {
    var drawable = LottieDrawable(_solid(opacity: _holdThenTerminal))
      ..setProgress(0);
    var changed = [
      for (var frame = 1; frame < 20; frame++)
        if (drawable.setProgress((frame + 0.5) / 20)) frame,
    ];
    expect(changed, [10]);
  });

  // Neither has a next keyframe to take its end value from.
  for (var (name, keyframe) in const [
    ('hold', '"h": 1'),
    ('eased', '"o": {"x": [0.3], "y": [0]}, "i": {"x": [0.7], "y": [1]}'),
  ]) {
    test('a single $name keyframe keeps its value', () async {
      var rotated = _bar(
        rotation: '{"a": 1, "k": [{"t": 0, "s": [90], $keyframe}]}',
      );
      expect(await _pixel(rotated, 0.5, 10, 3), _red);

      var colored = _bar(
        fill:
            '{"ty": "fl", "c": {"a": 1, "k": [{"t": 0, "s": [0, 1, 0, 1], $keyframe}]}, '
            '"o": {"a": 0, "k": 100}, "r": 1}',
      );
      expect(await _pixel(colored, 0.5, 10, 10), _green);

      // From red on the left to green on the right.
      var gradient = _bar(
        fill:
            '{"ty": "gf", "t": 1, "o": {"a": 0, "k": 100}, "r": 1, '
            '"s": {"a": 0, "k": [-8, 0]}, "e": {"a": 0, "k": [8, 0]}, '
            '"g": {"p": 2, "k": {"a": 1, "k": [{"t": 0, "s": [0, 1, 0, 0, 1, 0, 1, 0], $keyframe}]}}}',
      );
      var left = await _pixel(gradient, 0.5, 3, 10);
      var right = await _pixel(gradient, 0.5, 16, 10);
      expect(left.r, greaterThan(left.g));
      expect(right.g, greaterThan(right.r));
    });
  }

  test(
    'a held shape is drawn whole when the next shape has fewer points',
    () async {
      const square =
          '{"c": true, "v": [[2, 2], [18, 2], [18, 18], [2, 18]], '
          '"i": [[0, 0], [0, 0], [0, 0], [0, 0]], "o": [[0, 0], [0, 0], [0, 0], [0, 0]]}';
      const line =
          '{"c": false, "v": [[2, 2], [18, 2]], '
          '"i": [[0, 0], [0, 0]], "o": [[0, 0], [0, 0]]}';
      var composition = _shapeLayer(
        '{"ty": "sh", "ks": {"a": 1, "k": [{"t": 0, "s": [$square], "h": 1}, '
        '{"t": 10, "s": [$line], "h": 1}, {"t": 20, "s": [$line]}]}}, $_redFill',
      );
      expect(await _pixel(composition, 0.25, 3, 16), _red);
    },
  );
}

/// A 10x10 red solid in a 10x10 composition of 20 frames at 10 fps.
LottieComposition _solid({
  String opacity = '{"a": 0, "k": 100}',
  String position = '{"a": 0, "k": [0, 0, 0]}',
}) {
  return _composition(
    width: 10,
    layer:
        '''
{
  "ty": 1, "ind": 1, "nm": "Red solid", "sw": 10, "sh": 10, "sc": "#ff0000",
  "ip": 0, "op": 20, "st": 0, "sr": 1,
  "ks": {
    "o": $opacity, "r": {"a": 0, "k": 0}, "p": $position,
    "a": {"a": 0, "k": [0, 0, 0]}, "s": {"a": 0, "k": [100, 100, 100]}
  }
}''',
  );
}

const _redFill =
    '{"ty": "fl", "c": {"a": 0, "k": [1, 0, 0, 1]}, "o": {"a": 0, "k": 100}, "r": 1}';

/// A horizontal 16x4 bar centered in a 20x20 composition.
LottieComposition _bar({
  String rotation = '{"a": 0, "k": 0}',
  String fill = _redFill,
}) {
  return _shapeLayer(
    '{"ty": "rc", "d": 1, "s": {"a": 0, "k": [16, 4]}, "p": {"a": 0, "k": [0, 0]}, '
    '"r": {"a": 0, "k": 0}}, $fill',
    position: '[10, 10, 0]',
    rotation: rotation,
  );
}

/// A shape layer in a 20x20 composition of 20 frames at 10 fps.
LottieComposition _shapeLayer(
  String shapes, {
  String position = '[0, 0, 0]',
  String rotation = '{"a": 0, "k": 0}',
}) {
  return _composition(
    width: 20,
    layer:
        '''
{
  "ty": 4, "ind": 1, "nm": "Shape", "ip": 0, "op": 20, "st": 0, "sr": 1,
  "ks": {
    "o": {"a": 0, "k": 100}, "r": $rotation, "p": {"a": 0, "k": $position},
    "a": {"a": 0, "k": [0, 0, 0]}, "s": {"a": 0, "k": [100, 100, 100]}
  },
  "shapes": [$shapes]
}''',
  );
}

LottieComposition _composition({required int width, required String layer}) {
  return LottieComposition.parseJsonBytes(
    utf8.encode(
      '{"v": "5.7.4", "fr": 10, "ip": 0, "op": 20, "w": $width, "h": $width, '
      '"layers": [$layer]}',
    ),
  );
}

Future<Color> _pixel(
  LottieComposition composition,
  double progress,
  int x,
  int y,
) async {
  var drawable = LottieDrawable(composition)..setProgress(progress);
  var size = drawable.size;
  var recorder = PictureRecorder();
  drawable.draw(Canvas(recorder), Offset.zero & size);
  var picture = recorder.endRecording();
  var image = await picture.toImage(size.width.round(), size.height.round());
  var pixels = await image.toByteData();
  image.dispose();
  picture.dispose();
  var offset = (y * size.width.round() + x) * 4;
  return Color.fromARGB(
    pixels!.getUint8(offset + 3),
    pixels.getUint8(offset),
    pixels.getUint8(offset + 1),
    pixels.getUint8(offset + 2),
  );
}
