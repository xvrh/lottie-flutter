import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const _red = '[1, 0, 0, 1]';
const _blue = '[0, 0, 1, 1]';

/// A 10x10 composition covered by a rectangle filled with [color] and
/// [opacity], at [position] in a layer with [transform] (Lottie properties),
/// and with the given root [slots].
LottieComposition _composition({
  required String color,
  String opacity = '{"a": 0, "k": 100}',
  String position = '{"a": 0, "k": [5, 5]}',
  String transform = '{}',
  String? slots,
  bool slotsFirst = false,
}) {
  var slotsEntry = slots == null ? '' : '"slots": $slots,';
  return LottieComposition.parseJsonBytes(
    utf8.encode('''
{
  "v": "5.12.0", "fr": 10, "ip": 0, "op": 10, "w": 10, "h": 10,
  ${slotsFirst ? slotsEntry : ''}
  "layers": [{
    "ty": 4, "ind": 1, "ip": 0, "op": 10, "st": 0, "ks": $transform,
    "shapes": [
      {"ty": "rc", "p": $position, "s": {"a": 0, "k": [10, 10]}, "r": {"a": 0, "k": 0}},
      {"ty": "fl", "c": $color, "o": $opacity}
    ]
  }],
  ${slotsFirst ? '' : slotsEntry}
  "assets": []
}'''),
  );
}

/// The RGBA of the center of [composition] at [progress].
Future<List<int>> _center(
  LottieComposition composition, {
  double progress = 0,
}) async {
  var drawable = LottieDrawable(composition)..setProgress(progress);
  var recorder = PictureRecorder();
  drawable.draw(Canvas(recorder), const Rect.fromLTWH(0, 0, 10, 10));
  var image = await recorder.endRecording().toImage(10, 10);
  var pixels = (await image.toByteData(
    format: ImageByteFormat.rawStraightRgba,
  ))!;
  image.dispose();
  var offset = (5 * 10 + 5) * 4;
  return [for (var i = 0; i < 4; i++) pixels.getUint8(offset + i)];
}

void main() {
  test('A color takes the value of its slot', () async {
    var composition = _composition(
      color: '{"a": 0, "k": $_red, "sid": "main"}',
      slots: '{"main": {"p": {"a": 0, "k": $_blue}}}',
    );

    expect(await _center(composition), [0, 0, 255, 255]);
  });

  test('The slots can come before the layers', () async {
    var composition = _composition(
      color: '{"a": 0, "k": $_red, "sid": "main"}',
      slots: '{"main": {"p": {"a": 0, "k": $_blue}}}',
      slotsFirst: true,
    );

    expect(await _center(composition), [0, 0, 255, 255]);
  });

  test('A slot can be animated', () async {
    var composition = _composition(
      color: '{"a": 0, "k": $_red, "sid": "main"}',
      slots:
          '''
{"main": {"p": {"a": 1, "k": [
  {"t": 0, "s": $_blue, "o": {"x": [0], "y": [0]}, "i": {"x": [1], "y": [1]}},
  {"t": 5, "s": [0, 1, 0, 1]}
]}}}''',
    );

    expect(await _center(composition), [0, 0, 255, 255]);
    expect(await _center(composition, progress: 1), [0, 255, 0, 255]);
  });

  test('Any property can take the value of a slot', () async {
    var composition = _composition(
      color: '{"a": 0, "k": $_red}',
      opacity: '{"a": 0, "k": 100, "sid": "opacity"}',
      slots: '{"opacity": {"p": {"a": 0, "k": 50}}}',
    );

    expect(await _center(composition), [255, 0, 0, closeTo(128, 1)]);
  });

  test('A position takes the value of its slot', () async {
    var composition = _composition(
      color: '{"a": 0, "k": $_red}',
      // Out of the composition, unless the slot applies.
      position: '{"a": 0, "k": [25, 25], "sid": "position"}',
      slots: '{"position": {"p": {"a": 0, "k": [5, 5]}}}',
    );

    expect(await _center(composition), [255, 0, 0, 255]);
  });

  test('An anchor point takes the value of its slot', () async {
    var composition = _composition(
      color: '{"a": 0, "k": $_red}',
      // Moves the rectangle out of the composition, unless both slots apply.
      transform: '''
{"a": {"a": 0, "k": [20, 20], "sid": "anchor"},
 "p": {"a": 0, "k": [40, 40], "sid": "position"}}''',
      slots: '''
{"anchor": {"p": {"a": 0, "k": [0, 0]}},
 "position": {"p": {"a": 0, "k": [0, 0]}}}''',
    );

    expect(await _center(composition), [255, 0, 0, 255]);
  });

  test('A property keeps its own value without a matching slot', () async {
    var composition = _composition(
      color: '{"a": 0, "k": $_red, "sid": "missing"}',
      slots: '{"main": {"p": {"a": 0, "k": $_blue}}}',
    );

    expect(await _center(composition), [255, 0, 0, 255]);
  });

  test('The id of a slot inside a slot is ignored', () async {
    var composition = _composition(
      color: '{"a": 0, "k": $_red, "sid": "main"}',
      slots: '{"main": {"p": {"a": 0, "k": $_blue, "sid": "main"}}}',
    );

    expect(await _center(composition), [0, 0, 255, 255]);
  });
}
