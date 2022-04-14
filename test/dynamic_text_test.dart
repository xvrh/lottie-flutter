import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'utils.dart';

void main() {
  late LottieComposition composition;

  setUpAll(() async {
    composition = await LottieComposition.fromBytes(
        File('example/assets/Tests/DynamicText.json').readAsBytesSync());
  });

  void testGolden(String description, LottieDelegates delegates) async {
    var screenshotName = description
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), '')
        .replaceAll(' ', '_');

    var size = const Size(500, 400);
    testWidgets(description, (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FilmStrip(
            composition,
            delegates: delegates,
            size: size,
          ),
        ),
      );
      await tester.pump();
      await expectLater(find.byType(FilmStrip),
          matchesGoldenFile('goldens/dynamic_text/$screenshotName.png'));
    });
  }

  testGolden(
      'Dynamic text delegate',
      LottieDelegates(
          text: (input) => '🔥c️🔥👮🏿‍🔥',
          textStyle: (font) => const TextStyle(
              fontFamily: 'Roboto', fontFamilyFallback: ['Noto Emoji']),
          values: const []));

  testGolden(
    'Dynamic Text ValueDelegate',
    LottieDelegates(values: [
      ValueDelegate.text(['NAME'], value: 'Text with ValueDelegate')
    ]),
  );

  testGolden(
    'Dynamic Text ValueDelegate overallProgress',
    LottieDelegates(values: [
      ValueDelegate.text(['NAME'],
          callback: (frame) => '${frame.overallProgress}')
    ]),
  );

  testGolden(
    'Dynamic Text ValueDelegate startValue',
    LottieDelegates(values: [
      ValueDelegate.text(['NAME'], callback: (frame) => '${frame.startValue}!!')
    ]),
  );

  testGolden(
    'Dynamic Text ValueDelegate endValue',
    LottieDelegates(values: [
      ValueDelegate.text(['NAME'], callback: (frame) => '${frame.endValue}!!')
    ]),
  );

  testGolden(
    'Dynamic Text Emoji',
    LottieDelegates(
        textStyle: (font) => const TextStyle(
            fontFamily: 'Roboto', fontFamilyFallback: ['Noto Emoji']),
        values: [
          ValueDelegate.text(['NAME'], value: '🔥💪💯'),
        ]),
  );
}
