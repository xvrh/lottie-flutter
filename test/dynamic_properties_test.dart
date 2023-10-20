import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'utils.dart';

void main() {
  void testGolden(String description, ValueDelegate delegate,
      {double? progress, String? filePath}) {
    filePath ??= 'Tests/Shapes.json';

    var screenshotName = description
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), '')
        .replaceAll(' ', '_');

    testWidgets(description, (tester) async {
      var composition = await LottieComposition.fromBytes(
          File('example/assets/$filePath').readAsBytesSync());

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
          addRepaintBoundary: false,
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
            delegates: const LottieDelegates(values: []),
            addRepaintBoundary: false,
          ),
        );
        await tester.pump();
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
        value: const Offset(20, 20)),
  );

  testGolden(
    'Transform position',
    ValueDelegate.transformPosition(['Shape Layer 1', 'Rectangle'],
        value: const Offset(20, 20)),
  );

  testGolden(
    'Transform position (relative)',
    ValueDelegate.transformPosition(['Shape Layer 1', 'Rectangle'],
        relative: const Offset(20, 20)),
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
        value: const Offset(0.5, 0.5)),
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
        relative: const Offset(20, 20)),
  );

  testGolden(
    'Rectangle size',
    ValueDelegate.rectangleSize(
        ['Shape Layer 1', 'Rectangle', 'Rectangle Path 1'],
        relative: const Offset(30, 40)),
  );

  testGolden(
    'Ellipse position',
    ValueDelegate.position(['Shape Layer 1', 'Ellipse', 'Ellipse Path 1'],
        relative: const Offset(20, 20)),
  );

  testGolden(
    'Ellipse size',
    ValueDelegate.ellipseSize(['Shape Layer 1', 'Ellipse', 'Ellipse Path 1'],
        relative: const Offset(40, 60)),
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
        relative: const Offset(20, 20)),
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
        relative: const Offset(20, 20)),
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
        relative: const Offset(100, 100)),
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
        value: const Offset(2, 2)),
  );

  testGolden('Time remapping', ValueDelegate.timeRemap(['Circle 1'], value: 1),
      progress: 0.1);

  testGolden(
    'Color Filter',
    ValueDelegate.colorFilter(['**'],
        value: const ColorFilter.mode(Colors.green, BlendMode.srcATop)),
  );

  testGolden(
    'Null Color Filter',
    ValueDelegate.colorFilter(['**']),
  );

  testGolden(
    'Matte property',
    ValueDelegate.rectangleSize(
        ['Shape Layer 1', 'Rectangle 1', 'Rectangle Path 1'],
        value: const Offset(50, 50)),
    filePath: 'Tests/TrackMattes.json',
  );

  testGolden(
    'Blur',
    ValueDelegate.blurRadius(
      ['**'],
      value: 10,
    ),
  );

  testGolden(
    'Drop shadow',
    ValueDelegate.dropShadow(
      ['Shape Layer 1', '**'],
      value: const DropShadow(
        color: Colors.green,
        direction: 150,
        distance: 20,
        radius: 10,
      ),
    ),
  );

  testGolden(
    'Solid Color',
    ValueDelegate.color(
      ['Cyan Solid 1', '**'],
      value: Colors.yellow,
    ),
    filePath: 'Tests/SolidLayerTransform.json',
  );

  for (var progress in [0.0, 0.5, 1.0]) {
    testGolden(
        'Opacity interpolation ($progress)',
        ValueDelegate.transformOpacity(['Shape Layer 1', 'Rectangle'],
            callback: (frameInfo) => lerpDouble(10, 100,
                    Curves.linear.transform(frameInfo.overallProgress))!
                .round()),
        progress: progress);
  }

  testWidgets('warningShimmer', (tester) async {
    var size = const Size(500, 400);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

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
