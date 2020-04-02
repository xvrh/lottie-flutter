import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'utils.dart';

void main() {
  LottieComposition composition;

  setUpAll(() async {
    composition = await LottieComposition.fromBytes(
        File('assets/Tests/Shapes.json').readAsBytesSync());
  });

  void testGolden(String description, ValueDelegate delegate,
      {double progress}) async {
    var screenshotName = description
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), '')
        .replaceAll(' ', '_');

    testWidgets(description, (tester) async {
      var animation =
          AnimationController(vsync: tester, duration: composition.duration);
      if (progress != null) {
        animation.value = progress;
      }

      await tester.pumpWidget(
        Lottie(
          composition: composition,
          controller: animation,
          delegates: LottieDelegates(values: [delegate]),
        ),
      );
      await tester.pump();
      await expectLater(find.byType(Lottie),
          matchesGoldenFile('goldens/dynamic/$screenshotName.png'));

      if (progress == null || progress == 0) {
        await tester.pumpWidget(
          Lottie(
            composition: composition,
            controller: animation,
            delegates: LottieDelegates(values: []),
          ),
        );
        await tester.pump();
        await expectLater(find.byType(Lottie),
            matchesGoldenFile('goldens/dynamic_without_delegate.png'));
      }
    });
  }

  testGolden(
    'Fill color (Green)',
    ValueDelegate.color(['Shape Layer 1', 'Rectangle', 'Fill 1'],
        value: Colors.green),
  );

  testGolden(
    'Fill color (Yellow)',
    ValueDelegate.color(['Shape Layer 1', 'Rectangle', 'Fill 1'],
        value: Colors.yellow),
  );

  testGolden(
    'Fill opacity',
    ValueDelegate.opacity(['Shape Layer 1', 'Rectangle', 'Fill 1'], value: 50),
  );

  testGolden(
    'Stroke color',
    ValueDelegate.strokeColor(['Shape Layer 1', 'Rectangle', 'Stroke 1'],
        value: Colors.green),
  );

  testGolden(
    'Stroke width',
    ValueDelegate.strokeWidth(['Shape Layer 1', 'Rectangle', 'Stroke 1'],
        value: 50),
  );

  testGolden(
    'Stroke opacity',
    ValueDelegate.opacity(['Shape Layer 1', 'Rectangle', 'Stroke 1'],
        value: 50),
  );

  testGolden(
    'Transform anchor point',
    ValueDelegate.transformAnchorPoint(['Shape Layer 1', 'Rectangle'],
        value: Offset(20, 20)),
  );

  testGolden(
    'Transform position',
    ValueDelegate.transformPosition(['Shape Layer 1', 'Rectangle'],
        value: Offset(20, 20)),
  );

  testGolden(
    'Transform position (relative)',
    ValueDelegate.transformPosition(['Shape Layer 1', 'Rectangle'],
        relative: Offset(20, 20)),
  );

  testGolden(
    'Transform opacity',
    ValueDelegate.transformOpacity(['Shape Layer 1', 'Rectangle'], value: 50),
  );

  testGolden(
    'Transform rotation',
    ValueDelegate.transformRotation(['Shape Layer 1', 'Rectangle'], value: 45),
  );

  testGolden(
    'Transform scale',
    ValueDelegate.transformScale(['Shape Layer 1', 'Rectangle'],
        value: Offset(0.5, 0.5)),
  );

  testGolden(
    'Rectangle corner roundedness',
    ValueDelegate.cornerRadius(
        ['Shape Layer 1', 'Rectangle', 'Rectangle Path 1'],
        value: 7),
  );

  testGolden(
    'Rectangle position',
    ValueDelegate.position(['Shape Layer 1', 'Rectangle', 'Rectangle Path 1'],
        relative: Offset(20, 20)),
  );

  testGolden(
    'Rectangle size',
    ValueDelegate.rectangleSize(
        ['Shape Layer 1', 'Rectangle', 'Rectangle Path 1'],
        relative: Offset(30, 40)),
  );

  testGolden(
    'Ellipse position',
    ValueDelegate.position(['Shape Layer 1', 'Ellipse', 'Ellipse Path 1'],
        relative: Offset(20, 20)),
  );

  testGolden(
    'Ellipse size',
    ValueDelegate.ellipseSize(['Shape Layer 1', 'Ellipse', 'Ellipse Path 1'],
        relative: Offset(40, 60)),
  );

  testGolden(
    'Star points',
    ValueDelegate.polystarPoints(['Shape Layer 1', 'Star', 'Polystar Path 1'],
        value: 8),
  );

  testGolden(
    'Star rotation',
    ValueDelegate.polystarRotation(['Shape Layer 1', 'Star', 'Polystar Path 1'],
        value: 10),
  );

  testGolden(
    'Star position',
    ValueDelegate.position(['Shape Layer 1', 'Star', 'Polystar Path 1'],
        relative: Offset(20, 20)),
  );

  testGolden(
    'Star inner radius',
    ValueDelegate.polystarInnerRadius(
        ['Shape Layer 1', 'Star', 'Polystar Path 1'],
        value: 10),
  );

  testGolden(
    'Star inner roundedness',
    ValueDelegate.polystarInnerRoundedness(
        ['Shape Layer 1', 'Star', 'Polystar Path 1'],
        value: 100),
  );

  testGolden(
    'Star outer radius',
    ValueDelegate.polystarOuterRadius(
        ['Shape Layer 1', 'Star', 'Polystar Path 1'],
        value: 60),
  );

  testGolden(
    'Star outer roundedness',
    ValueDelegate.polystarOuterRoundedness(
        ['Shape Layer 1', 'Star', 'Polystar Path 1'],
        value: 100),
  );

  testGolden(
    'Polygon points',
    ValueDelegate.polystarPoints(['Shape Layer 1', 'Star', 'Polystar Path 1'],
        value: 8),
  );

  testGolden(
    'Polygon rotation',
    ValueDelegate.polystarRotation(['Shape Layer 1', 'Star', 'Polystar Path 1'],
        value: 10),
  );

  testGolden(
    'Polygon position',
    ValueDelegate.position(['Shape Layer 1', 'Star', 'Polystar Path 1'],
        relative: Offset(20, 20)),
  );

  testGolden(
    'Polygon radius',
    ValueDelegate.polystarOuterRadius(
        ['Shape Layer 1', 'Star', 'Polystar Path 1'],
        relative: 60),
  );

  testGolden(
    'Polygon roundedness',
    ValueDelegate.polystarOuterRoundedness(
        ['Shape Layer 1', 'Star', 'Polystar Path 1'],
        value: 100),
  );

  testGolden(
    'Repeater transform position',
    ValueDelegate.transformPosition(
        ['Shape Layer 1', 'Repeater Shape', 'Repeater 1'],
        relative: Offset(100, 100)),
  );

  testGolden(
    'Repeater transform start opacity',
    ValueDelegate.transformStartOpacity(
        ['Shape Layer 1', 'Repeater Shape', 'Repeater 1'],
        value: 25),
  );

  testGolden(
    'Repeater transform end opacity',
    ValueDelegate.transformEndOpacity(
        ['Shape Layer 1', 'Repeater Shape', 'Repeater 1'],
        value: 25),
  );

  testGolden(
    'Repeater transform rotation',
    ValueDelegate.transformRotation(
        ['Shape Layer 1', 'Repeater Shape', 'Repeater 1'],
        value: 45),
  );

  testGolden(
    'Repeater transform scale',
    ValueDelegate.transformScale(
        ['Shape Layer 1', 'Repeater Shape', 'Repeater 1'],
        value: Offset(2, 2)),
  );

  testGolden('Time remapping', ValueDelegate.timeRemap(['Circle 1'], value: 1),
      progress: 0.1);

  testGolden(
    'Color Filter',
    ValueDelegate.colorFilter(['**'],
        value: ColorFilter.mode(Colors.green, BlendMode.srcATop)),
  );

  testGolden(
    'Null Color Filter',
    ValueDelegate.colorFilter(['**'], value: null),
  );

  for (var progress in [0.0, 0.5, 1.0]) {
    testGolden(
        'Opacity interpolation ($progress)',
        ValueDelegate.transformOpacity(['Shape Layer 1', 'Rectangle'],
            callback: (frameInfo) => lerpDouble(
                    10, 100, Curves.linear.transform(frameInfo.overallProgress))
                .round()),
        progress: progress);
  }

  testWidgets('warningShimmer', (tester) async {
    var size = Size(500, 400);
    tester.binding.window.physicalSizeTestValue = size;
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    var composition = await LottieComposition.fromBytes(
        File('test/data/warningShimmer.json').readAsBytesSync());

    var delegates = <String, List<ValueDelegate>>{
      '1': [
        for (var i in ['1', '2', '5'])
          ValueDelegate.color(['Layer $i Outlines', '**'], value: Colors.red),
        for (var i in ['3', '4'])
          ValueDelegate.color(['Layer $i Outlines', '**'],
              value: Colors.greenAccent),
      ],
      '2': [
        for (var i in ['1', '2', '5'])
          ValueDelegate.color(['Layer $i Outlines', 'Group 1', '*'],
              value: Colors.red),
        for (var i in ['3', '4'])
          ValueDelegate.color(['Layer $i Outlines', 'Group 1', '*'],
              value: Colors.greenAccent),
      ],
      '3': [
        for (var i in ['1', '2', '5'])
          ValueDelegate.color(['Layer $i Outlines', 'Group 1', 'Fill 1'],
              value: Colors.red),
        for (var i in ['3', '4'])
          ValueDelegate.color(['Layer $i Outlines', 'Group 1', 'Fill 1'],
              value: Colors.greenAccent),
      ],
    };

    for (var variant in delegates.entries) {
      await tester.pumpWidget(
        FilmStrip(
          composition,
          size: size,
          delegates: LottieDelegates(
            values: variant.value,
          ),
        ),
      );

      await expectLater(find.byType(FilmStrip),
          matchesGoldenFile('goldens/warningShimmer_${variant.key}.png'));
    }
  });
}
