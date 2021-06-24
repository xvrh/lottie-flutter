import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('Dynamic test', (tester) async {
    var composition = await LottieComposition.fromBytes(
        File('example/assets/Tests/DynamicText.json').readAsBytesSync());

    await tester.pumpWidget(
      MaterialApp(
        home: Lottie(
          composition: composition,
          animate: false,
          delegates: LottieDelegates(
              text: (input) => '🔥c️🔥👮🏿‍🔥',
              textStyle: (font) => const TextStyle(
                  fontFamily: 'Roboto', fontFamilyFallback: ['Noto Emoji']),
              values: const []),
        ),
      ),
    );

    await expectLater(
        find.byType(Lottie), matchesGoldenFile('goldens/dynamic_text.png'));
  });
}
