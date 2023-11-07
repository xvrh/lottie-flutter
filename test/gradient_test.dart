import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  void testGradient(String name, ValueDelegate valueDelegate) {
    testWidgets(name, (tester) async {
      var composition = await LottieComposition.fromBytes(
          File('example/assets/Tests/DynamicGradient.json').readAsBytesSync());

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
          value: const [Color(0xFFFFFF00), Color(0xFF00FF00)]));

  testGradient(
      'Radial Gradient Fill',
      ValueDelegate.gradientColor(['Radial', 'Rectangle', 'Gradient Fill'],
          value: const [Color(0xFFFFFF00), Color(0xFF00FF00)]));

  testGradient(
      'Linear Gradient Stroke',
      ValueDelegate.gradientColor(['Linear', 'Rectangle', 'Gradient Stroke'],
          value: const [Color(0xFFFFFF00), Color(0xFF00FF00)]));

  testGradient(
      'Radial Gradient Stroke',
      ValueDelegate.gradientColor(['Radial', 'Rectangle', 'Gradient Stroke'],
          value: const [Color(0xFFFFFF00), Color(0xFF00FF00)]));

  testGradient(
      'Opacity Linear Gradient Fill',
      ValueDelegate.opacity(['Linear', 'Rectangle', 'Gradient Fill'],
          value: 50));

  testWidgets('Can change gradient dynamically with value', (tester) async {
    var composition = await LottieComposition.fromBytes(
        File('example/assets/blub.json').readAsBytesSync());

    var animation =
        AnimationController(vsync: tester, duration: composition.duration);

    await tester.pumpWidget(
      Lottie(
        composition: composition,
        controller: animation,
        delegates: LottieDelegates(values: [
          ValueDelegate.gradientColor(
            const ['灯光', '灯光', 'Gradient Fill 2'],
            value: [Colors.yellow, Colors.white],
          ),
        ]),
      ),
    );
    await tester.pumpWidget(
      Lottie(
        composition: composition,
        controller: animation,
        delegates: LottieDelegates(values: [
          ValueDelegate.gradientColor(
            const ['灯光', '灯光', 'Gradient Fill 2'],
            value: [Colors.red, Colors.white],
          ),
        ]),
      ),
    );

    await expectLater(find.byType(Lottie),
        matchesGoldenFile('goldens/gradients/blub_red_value.png'));
  });

  testWidgets('Can change gradient dynamically with callback', (tester) async {
    var composition = await LottieComposition.fromBytes(
        File('example/assets/blub.json').readAsBytesSync());

    var animation =
        AnimationController(vsync: tester, duration: composition.duration);

    await tester.pumpWidget(
      Lottie(
        composition: composition,
        controller: animation,
        delegates: LottieDelegates(values: [
          ValueDelegate.gradientColor(
            const ['灯光', '灯光', 'Gradient Fill 2'],
            callback: (_) => [Colors.yellow, Colors.white],
          ),
        ]),
      ),
    );
    await tester.pumpWidget(
      Lottie(
        composition: composition,
        controller: animation,
        delegates: LottieDelegates(values: [
          ValueDelegate.gradientColor(
            const ['灯光', '灯光', 'Gradient Fill 2'],
            callback: (_) => [Colors.red, Colors.white],
          ),
        ]),
      ),
    );

    await expectLater(find.byType(Lottie),
        matchesGoldenFile('goldens/gradients/blub_red_callback.png'));
  });
}
