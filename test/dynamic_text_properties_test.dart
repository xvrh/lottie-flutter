import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

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
    ValueDelegate.color(['Text'], callback: (_) => Colors.green),
  );

  testGolden(
    'Text Stroke (Red -> Yellow)',
    ValueDelegate.strokeColor(['Text'], callback: (_) => Colors.yellow),
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
