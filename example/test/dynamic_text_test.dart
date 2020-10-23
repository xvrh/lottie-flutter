import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('Dynamic test', (tester) async {
    tester.binding.window.physicalSizeTestValue = Size(500, 400);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    var composition = await LottieComposition.fromBytes(
        File('assets/Tests/DynamicText.json').readAsBytesSync());

    await tester.pumpWidget(
      MaterialApp(
        home: Lottie(
          composition: composition,
          animate: false,
          delegates: LottieDelegates(
              text: (input) => '🔥c️🔥👮🏿‍🔥',
              textStyle: (font) => TextStyle(
                  fontFamily: 'Roboto', fontFamilyFallback: ['Noto Emoji']),
              values: []),
        ),
      ),
    );

    await expectLater(
        find.byType(Lottie), matchesGoldenFile('goldens/dynamic_text.png'));
  });
}
