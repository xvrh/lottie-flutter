import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  setUpAll(() async {
    await loadFontFromList(
        File('example/assets/fonts/Roboto.ttf').readAsBytesSync(),
        fontFamily: 'Roboto');
  });

  testWidgets('Dynamic test', (tester) async {
    var composition = await LottieComposition.fromBytes(
        File('example/assets/Tests/DynamicText.json').readAsBytesSync());

    await tester.pumpWidget(Lottie(
      animate: false,
      composition: composition,
    ));

    await expectLater(
        find.byType(Lottie), matchesGoldenFile('golden/dynamic_text/1.png'));

    await tester.pumpWidget(Lottie(
      composition: composition,
      animate: false,
      options: LottieOptions(
          textDelegate: (input) => '**$input**',
          fontDelegate: (font) => 'Roboto'),
    ));

    await expectLater(
        find.byType(Lottie), matchesGoldenFile('golden/dynamic_text/2.png'));
  });
}
