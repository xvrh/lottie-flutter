import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/model/content/gradient_color.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  void testGradient(String name, ValueDelegate valueDelegate) {
    testWidgets(name, (tester) async {
      var composition = await LottieComposition.fromBytes(
        File('example/assets/Tests/DynamicGradient.json').readAsBytesSync(),
      );

      var animation = AnimationController(
        vsync: tester,
        duration: composition.duration,
      );

      await tester.pumpWidget(
        Lottie(
          composition: composition,
          controller: animation,
          delegates: LottieDelegates(values: [valueDelegate]),
        ),
      );

      var screenshotName = name
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9 ]'), '')
          .replaceAll(' ', '_');

      await expectLater(
        find.byType(Lottie),
        matchesGoldenFile('goldens/gradients/$screenshotName.png'),
      );
    });
  }

  testGradient(
    'Linear Gradient Fill',
    ValueDelegate.gradientColor(
      ['Linear', 'Rectangle', 'Gradient Fill'],
      value: const [Color(0xFFFFFF00), Color(0xFF00FF00)],
    ),
  );

  testGradient(
    'Radial Gradient Fill',
    ValueDelegate.gradientColor(
      ['Radial', 'Rectangle', 'Gradient Fill'],
      value: const [Color(0xFFFFFF00), Color(0xFF00FF00)],
    ),
  );

  testGradient(
    'Linear Gradient Stroke',
    ValueDelegate.gradientColor(
      ['Linear', 'Rectangle', 'Gradient Stroke'],
      value: const [Color(0xFFFFFF00), Color(0xFF00FF00)],
    ),
  );

  testGradient(
    'Radial Gradient Stroke',
    ValueDelegate.gradientColor(
      ['Radial', 'Rectangle', 'Gradient Stroke'],
      value: const [Color(0xFFFFFF00), Color(0xFF00FF00)],
    ),
  );

  testGradient(
    'Opacity Linear Gradient Fill',
    ValueDelegate.opacity(['Linear', 'Rectangle', 'Gradient Fill'], value: 50),
  );

  testWidgets('Can change gradient dynamically with value', (tester) async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/blub.json').readAsBytesSync(),
    );

    var animation = AnimationController(
      vsync: tester,
      duration: composition.duration,
    );

    await tester.pumpWidget(
      Lottie(
        composition: composition,
        controller: animation,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.gradientColor(
              const ['灯光', '灯光', 'Gradient Fill 2'],
              value: [Colors.yellow, Colors.white],
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      Lottie(
        composition: composition,
        controller: animation,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.gradientColor(
              const ['灯光', '灯光', 'Gradient Fill 2'],
              value: [Colors.red, Colors.white],
            ),
          ],
        ),
      ),
    );

    await expectLater(
      find.byType(Lottie),
      matchesGoldenFile('goldens/gradients/blub_red_value.png'),
    );
  });

  testWidgets('Can change gradient dynamically with callback', (tester) async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/blub.json').readAsBytesSync(),
    );

    var animation = AnimationController(
      vsync: tester,
      duration: composition.duration,
    );

    await tester.pumpWidget(
      Lottie(
        composition: composition,
        controller: animation,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.gradientColor(const [
              '灯光',
              '灯光',
              'Gradient Fill 2',
            ], callback: (_) => [Colors.yellow, Colors.white]),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      Lottie(
        composition: composition,
        controller: animation,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.gradientColor(const [
              '灯光',
              '灯光',
              'Gradient Fill 2',
            ], callback: (_) => [Colors.red, Colors.white]),
          ],
        ),
      ),
    );

    await expectLater(
      find.byType(Lottie),
      matchesGoldenFile('goldens/gradients/blub_red_callback.png'),
    );
  });

  test('Gradient color callback receives the current colors', () async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/Tests/DynamicGradient.json').readAsBytesSync(),
    );

    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    var startValues = <List<Color>?>[];
    var endValues = <List<Color>?>[];
    var drawable = LottieDrawable(composition)
      ..delegates = LottieDelegates(
        values: [
          for (var keyPath in _dynamicGradients)
            ValueDelegate.gradientColor(
              keyPath,
              callback: (frame) {
                startValues.add(frame.startValue);
                endValues.add(frame.endValue);
                return const [Color(0xFFFFFF00), Color(0xFF00FF00)];
              },
            ),
        ],
      );

    // Draw twice: the second frame must still receive the gradient's own
    // colors, not the ones returned by the callback for the first frame.
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    for (var i = 0; i < 2; i++) {
      drawable.draw(canvas, Offset.zero & drawable.size);
    }
    recorder.endRecording().dispose();

    // 4 gradients, drawn twice.
    expect(startValues, hasLength(8));
    expect(startValues, everyElement([white, black]));
    expect(endValues, everyElement([white, black]));
  });

  test('Removing a gradient color delegate restores the colors', () async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/Tests/DynamicGradient.json').readAsBytesSync(),
    );
    var drawable = LottieDrawable(composition);

    // A pixel of the linear fill left of where its gradient starts, so it has
    // the first color of the gradient.
    Future<Color> pixel() async =>
        (await _linearFillPixels(drawable, const [95])).single;

    expect(await pixel(), const Color(0xFFFFFFFF));

    drawable.delegates = LottieDelegates(
      values: [
        ValueDelegate.gradientColor([
          'Linear',
          'Rectangle',
          'Gradient Fill',
        ], callback: (_) => const [Color(0xFFFFFF00), Color(0xFF00FF00)]),
      ],
    );
    expect(await pixel(), const Color(0xFFFFFF00));

    drawable.delegates = null;
    expect(await pixel(), const Color(0xFFFFFFFF));
  });

  test(
    'Gradient colors are spread over the stops when their number differs',
    () async {
      var composition = await LottieComposition.fromBytes(
        File('example/assets/Tests/DynamicGradient.json').readAsBytesSync(),
      );
      const red = Color(0xFFFF0000);
      const green = Color(0xFF00FF00);
      const blue = Color(0xFF0000FF);

      // The gradients have 2 stops. Before, at the middle and after the linear
      // fill's gradient.
      Future<List<Color>> draw(List<Color> colors) {
        var drawable = LottieDrawable(composition)
          ..delegates = LottieDelegates(
            values: [
              for (var keyPath in _dynamicGradients)
                ValueDelegate.gradientColor(keyPath, value: colors),
            ],
          );
        return _linearFillPixels(drawable, const [95, 182, 270]);
      }

      var [start, middle, end] = await draw(const [red, green, blue]);
      expect(start, red);
      expect(middle.r, closeTo(0, 0.02));
      expect(middle.g, closeTo(1, 0.02));
      expect(middle.b, closeTo(0, 0.02));
      expect(end, blue);

      expect(await draw(const [red]), everyElement(red));
    },
  );

  test('GradientColor.withColors', () {
    const red = Color(0xFFFF0000);
    const green = Color(0xFF00FF00);
    const blue = Color(0xFF0000FF);
    var gradient = GradientColor([0.2, 0.5, 0.8], [red, green, blue]);

    void check(
      List<Color> colors,
      List<Color> expectedColors,
      List<double> expectedPositions,
    ) {
      var (resultColors, resultPositions) = gradient.withColors(colors);
      expect(resultColors, expectedColors);
      expect(resultPositions, [
        for (var position in expectedPositions) closeTo(position, 1e-9),
      ]);
    }

    check([blue, green, red], [blue, green, red], [0.2, 0.5, 0.8]);
    check([red, blue], [red, blue], [0.2, 0.8]);
    check([red, green, blue, red], [red, green, blue, red], [
      0.2,
      0.4,
      0.6,
      0.8,
    ]);
    check([red], [red, red], [0.2, 0.8]);
    check([], [red, green, blue], [0.2, 0.5, 0.8]);
  });
}

const _dynamicGradients = [
  ['Linear', 'Rectangle', 'Gradient Fill'],
  ['Radial', 'Rectangle', 'Gradient Fill'],
  ['Linear', 'Rectangle', 'Gradient Stroke'],
  ['Radial', 'Rectangle', 'Gradient Stroke'],
];

/// Pixels on the horizontal middle line of the linear fill of
/// `DynamicGradient.json`, whose gradient goes from x = 107 to x = 257.
Future<List<Color>> _linearFillPixels(
  LottieDrawable drawable,
  List<int> xs,
) async {
  var width = drawable.size.width.toInt();
  var height = drawable.size.height.toInt();
  var recorder = PictureRecorder();
  drawable.draw(Canvas(recorder), Offset.zero & drawable.size);
  var picture = recorder.endRecording();
  var image = await picture.toImage(width, height);
  var bytes = (await image.toByteData())!;
  image.dispose();
  picture.dispose();
  var pixels = <Color>[];
  for (var x in xs) {
    var offset = (202 * width + x) * 4;
    pixels.add(
      Color.fromARGB(
        bytes.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      ),
    );
  }
  return pixels;
}
