import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

// Material's colors, which the goldens were drawn with.
const _green = Color(0xFF4CAF50);
const _yellow = Color(0xFFFFEB3B);

void main() {
  late LottieComposition composition;

  setUpAll(() async {
    composition = await LottieComposition.fromBytes(
      File('example/assets/Tests/Text.json').readAsBytesSync(),
    );
  });

  void testGolden(String description, ValueDelegate delegate) async {
    var screenshotName = description
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), '')
        .replaceAll(' ', '_');

    testWidgets(description, (tester) async {
      await tester.pumpWidget(
        Lottie(
          composition: composition,
          delegates: LottieDelegates(values: [delegate]),
          addRepaintBoundary: false,
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(Lottie),
        matchesGoldenFile('goldens/dynamic_text/$screenshotName.png'),
      );
    });
  }

  testGolden(
    'Text Fill (Blue -> Green)',
    ValueDelegate.color(['Text'], callback: (_) => _green),
  );

  testGolden(
    'Text Stroke (Red -> Yellow)',
    ValueDelegate.strokeColor(['Text'], callback: (_) => _yellow),
  );

  testGolden(
    'Text Stroke Width',
    ValueDelegate.strokeWidth(['Text'], callback: (_) => 200),
  );

  testGolden(
    'Text Tracking 1',
    ValueDelegate.textTracking(['Text'], callback: (_) => 20),
  );

  testGolden(
    'Text Tracking 2',
    ValueDelegate.textSize(['Text'], callback: (_) => 60),
  );
}
