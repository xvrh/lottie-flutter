import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  void testGradient(String name, ValueDelegate valueDelegate) {
    testWidgets(name, (tester) async {
      tester.binding.window.physicalSizeTestValue = Size(500, 400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      var composition = await LottieComposition.fromBytes(
          File('assets/Tests/DynamicGradient.json').readAsBytesSync());

      var animation =
          AnimationController(vsync: tester, duration: composition.duration);

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

      await expectLater(find.byType(Lottie),
          matchesGoldenFile('goldens/gradients/$screenshotName.png'));
    });
  }

  testGradient(
      'Linear Gradient Fill',
      ValueDelegate.gradientColor(['Linear', 'Rectangle', 'Gradient Fill'],
          value: [Color(0xFFFFFF00), Color(0xFF00FF00)]));

  testGradient(
      'Radial Gradient Fill',
      ValueDelegate.gradientColor(['Radial', 'Rectangle', 'Gradient Fill'],
          value: [Color(0xFFFFFF00), Color(0xFF00FF00)]));

  testGradient(
      'Linear Gradient Stroke',
      ValueDelegate.gradientColor(['Linear', 'Rectangle', 'Gradient Stroke'],
          value: [Color(0xFFFFFF00), Color(0xFF00FF00)]));

  testGradient(
      'Radial Gradient Stroke',
      ValueDelegate.gradientColor(['Radial', 'Rectangle', 'Gradient Stroke'],
          value: [Color(0xFFFFFF00), Color(0xFF00FF00)]));

  testGradient(
      'Opacity Linear Gradient Fill',
      ValueDelegate.opacity(['Linear', 'Rectangle', 'Gradient Fill'],
          value: 50));
}
