import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('Dynamic test', (tester) async {
    var composition = await LottieComposition.fromBytes(
        File('assets/Tests/DynamicText.json').readAsBytesSync());

    await tester.pumpWidget(MaterialApp(
      home: DefaultTextStyle.merge(
          style: TextStyle(fontFamily: 'Roboto'), child: Text('hello')),
    ));

    await expectLater(
        find.byType(Text), matchesGoldenFile('goldens/dynamic_text/1.png'));

    await tester.pumpWidget(DefaultTextStyle(
      style: TextStyle(fontFamily: 'Roboto'),
      child: MaterialApp(
        home: Lottie(
          composition: composition,
          animate: false,
          delegates: LottieDelegates(
              text: (input) => '****',
              textStyle: (font) => TextStyle(fontFamily: 'Roboto'),
              values: []),
          textTransform: (input) => '**$input**',
          textStyleFactory: (font) => TextStyle(fontFamily: 'Roboto'),
        ),
      ),
    ));

    await tester.pumpWidget(DefaultTextStyle(
      style: TextStyle(fontFamily: 'Roboto'),
      child: MaterialApp(
        home: Lottie(
          composition: composition,
          animate: false,
          modifiers: LottieModifiers(
            text: (input) => '****',
            textStyle: (font) => TextStyle(fontFamily: 'Roboto'),
            values: [],
          ),
          textTransform: (input) => '**$input**',
          textStyleFactory: (font) => TextStyle(fontFamily: 'Roboto'),
        ),
      ),
    ));

    await expectLater(
        find.byType(Lottie), matchesGoldenFile('goldens/dynamic_text/2.png'));
  });
}
