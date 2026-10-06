import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'gaussian blur and drop shadow are not reported as unsupported',
    () async {
      var composition = await LottieComposition.fromBytes(
        _bytes(_blurAnimation(12)),
      );
      expect(
        composition.warnings.where(
          (warning) => warning.contains('layer effects'),
        ),
        isEmpty,
      );
    },
  );

  test('other layer effects are still reported', () async {
    var composition = await LottieComposition.fromBytes(
      _bytes(
        _composition([
          _shape(effects: [_strokeEffect()]),
        ]),
      ),
    );
    expect(
      composition.warnings.any((warning) => warning.contains('Stroke')),
      isTrue,
    );
  });

  testWidgets('gaussian blur spreads past the shape', (tester) async {
    await _pumpLottie(tester, _bytes(_blurAnimation(20)));
    var pixels = await _pixels(tester);
    var center = _pixel(pixels, 50, 50);
    var halo = _pixel(pixels, 50, 28);
    var corner = _pixel(pixels, 2, 2);

    expect(center.a, greaterThan(60));
    expect(halo.a, greaterThan(10));
    expect(halo.a, lessThan(center.a));
    expect(corner.a, lessThan(15));
  });

  testWidgets('a large gaussian blur stays a soft halo', (tester) async {
    await _pumpLottie(tester, _bytes(_blurAnimation(200)));
    var pixels = await _pixels(tester);
    var center = _pixel(pixels, 50, 50);
    var halo = _pixel(pixels, 50, 8);

    expect(center.a, greaterThan(0));
    expect(halo.a, greaterThan(0));
  });

  testWidgets('drop shadow on a nested precomp is drawn once', (tester) async {
    await _pumpLottie(tester, _bytes(_nestedShadow()));
    var pixels = await _pixels(tester);
    var shape = _pixel(pixels, 50, 50);
    var shadow = _pixel(pixels, 72, 50);
    var clear = _pixel(pixels, 72, 20);

    expect(shape.a, greaterThan(200));
    expect(shadow.a, greaterThan(40));
    expect(shadow.r, lessThan(40));
    expect(clear.a, lessThan(15));
  });

  testWidgets('blur still applies when the layer is masked', (tester) async {
    await _pumpLottie(tester, _bytes(_maskedBlur()));
    var pixels = await _pixels(tester);
    var center = _pixel(pixels, 52, 50).a;
    var edge = _pixel(pixels, 20, 50).a;
    // A masked square with no blur would be fully opaque on the visible side.
    expect(center, greaterThan(10));
    expect(center, lessThan(80));
    expect(edge, lessThan(center));
  });
}

Future<void> _pumpLottie(WidgetTester tester, List<int> bytes) async {
  tester.view.physicalSize = const Size(100, 100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  var composition = await LottieComposition.fromBytes(bytes);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('capture'),
      child: ColoredBox(
        color: const Color(0x00000000),
        child: Lottie(composition: composition, animate: false),
      ),
    ),
  );
  await tester.pump();
}

Future<ByteData> _pixels(WidgetTester tester) async {
  var boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('capture')),
  );
  var image = await tester.runAsync(() => boundary.toImage());
  var data = await tester.runAsync(() => image!.toByteData());
  image!.dispose();
  return data!;
}

_Rgba _pixel(ByteData data, int x, int y) {
  var offset = (y * 100 + x) * 4;
  return _Rgba(
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  );
}

class _Rgba {
  final int r;
  final int g;
  final int b;
  final int a;

  _Rgba(this.r, this.g, this.b, this.a);
}

List<int> _bytes(Map<String, Object?> composition) {
  return utf8.encode(jsonEncode(composition));
}

Map<String, Object?> _blurAnimation(num blurriness) {
  return _composition([
    _shape(effects: [_gaussianBlur(blurriness)]),
  ]);
}

Map<String, Object?> _nestedShadow() {
  return _composition(
    [
      _precomp(name: 'outer', refId: 'mid', effects: [_dropShadow()]),
    ],
    assets: [
      _asset('mid', [_precomp(name: 'inner precomp', refId: 'inner')]),
      _asset('inner', [_shape()]),
    ],
  );
}

Map<String, Object?> _composition(
  List<Map<String, Object?>> layers, {
  List<Map<String, Object?>> assets = const [],
}) {
  return {
    'v': '5.7.0',
    'fr': 30,
    'ip': 0,
    'op': 30,
    'w': 100,
    'h': 100,
    'nm': 'effects',
    'ddd': 0,
    'assets': assets,
    'layers': layers,
  };
}

Map<String, Object?> _asset(String id, List<Map<String, Object?>> layers) {
  return {'id': id, 'layers': layers};
}

Map<String, Object?> _gaussianBlur(num blurriness) {
  return {
    'ty': 29,
    'nm': 'Gaussian Blur',
    'en': 1,
    'ef': [
      {
        'ty': 0,
        'nm': 'Blurriness',
        'v': {'a': 0, 'k': blurriness},
      },
      {
        'ty': 7,
        'nm': 'Blur Dimensions',
        'v': {'a': 0, 'k': 1},
      },
    ],
  };
}

Map<String, Object?> _strokeEffect() {
  return {'ty': 5, 'nm': 'Stroke', 'en': 1, 'ef': <Object?>[]};
}

Map<String, Object?> _dropShadow() {
  return {
    'ty': 25,
    'nm': 'Drop Shadow',
    'en': 1,
    'ef': [
      {
        'ty': 2,
        'nm': 'Shadow Color',
        'v': {
          'a': 0,
          'k': [0, 0, 0],
        },
      },
      {
        'ty': 0,
        'nm': 'Opacity',
        'v': {'a': 0, 'k': 255},
      },
      {
        'ty': 1,
        'nm': 'Direction',
        'v': {'a': 0, 'k': 90},
      },
      {
        'ty': 0,
        'nm': 'Distance',
        'v': {'a': 0, 'k': 20},
      },
      {
        'ty': 0,
        'nm': 'Softness',
        'v': {'a': 0, 'k': 2},
      },
      {
        'ty': 7,
        'nm': 'Shadow Only',
        'v': {'a': 0, 'k': 0},
      },
    ],
  };
}

Map<String, Object?> _maskedBlur() {
  var layer = _shape(effects: [_gaussianBlur(24)]);
  layer['masksProperties'] = [
    {
      'inv': false,
      'mode': 'a',
      'pt': {
        'a': 0,
        'k': {
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
          'v': [
            [0, 0],
            [50, 0],
            [50, 100],
            [0, 100],
          ],
          'c': true,
        },
      },
      'o': {'a': 0, 'k': 100},
      'nm': 'Mask 1',
    },
  ];
  return _composition([layer]);
}

Map<String, Object?> _shape({List<Map<String, Object?>> effects = const []}) {
  return {
    'ddd': 0,
    'ind': 1,
    'ty': 4,
    'nm': 'shape',
    'sr': 1,
    'ks': _transform(),
    'ao': 0,
    if (effects.isNotEmpty) 'ef': effects,
    'shapes': [
      {
        'ty': 'gr',
        'nm': 'Group',
        'it': [
          {
            'ty': 'rc',
            'd': 1,
            's': {
              'a': 0,
              'k': [20, 20],
            },
            'p': {
              'a': 0,
              'k': [0, 0],
            },
            'r': {'a': 0, 'k': 0},
            'nm': 'Rect',
          },
          {
            'ty': 'fl',
            'c': {
              'a': 0,
              'k': [1, 1, 1, 1],
            },
            'o': {'a': 0, 'k': 100},
            'r': 1,
            'nm': 'Fill',
          },
          {
            'ty': 'tr',
            'p': {
              'a': 0,
              'k': [0, 0],
            },
            'a': {
              'a': 0,
              'k': [0, 0],
            },
            's': {
              'a': 0,
              'k': [100, 100],
            },
            'r': {'a': 0, 'k': 0},
            'o': {'a': 0, 'k': 100},
            'sk': {'a': 0, 'k': 0},
            'sa': {'a': 0, 'k': 0},
            'nm': 'Transform',
          },
        ],
      },
    ],
    'ip': 0,
    'op': 30,
    'st': 0,
    'bm': 0,
  };
}

Map<String, Object?> _precomp({
  required String name,
  required String refId,
  List<Map<String, Object?>> effects = const [],
}) {
  return {
    'ddd': 0,
    'ind': 1,
    'ty': 0,
    'nm': name,
    'refId': refId,
    'sr': 1,
    'ks': _transform(position: [0, 0, 0]),
    'ao': 0,
    if (effects.isNotEmpty) 'ef': effects,
    'w': 100,
    'h': 100,
    'ip': 0,
    'op': 30,
    'st': 0,
    'bm': 0,
  };
}

Map<String, Object?> _transform({List<num> position = const [50, 50, 0]}) {
  return {
    'o': {'a': 0, 'k': 100},
    'r': {'a': 0, 'k': 0},
    'p': {'a': 0, 'k': position},
    'a': {
      'a': 0,
      'k': [0, 0, 0],
    },
    's': {
      'a': 0,
      'k': [100, 100, 100],
    },
  };
}
