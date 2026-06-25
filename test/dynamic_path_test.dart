import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('ValueDelegate.path overrides a shape outline', (tester) async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/Tests/LargeSquare.json').readAsBytesSync(),
    );

    var customPath = Path()
      ..moveTo(250, 100)
      ..lineTo(400, 250)
      ..lineTo(250, 400)
      ..lineTo(100, 250)
      ..close();

    Widget build(LottieDelegates? delegates) => Lottie(
      composition: composition,
      delegates: delegates,
      addRepaintBoundary: false,
    );

    await tester.pumpWidget(
      build(
        LottieDelegates(
          values: [
            ValueDelegate.path(['**'], value: customPath),
          ],
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(Lottie),
      matchesGoldenFile('goldens/dynamic_path_override.png'),
    );

    await tester.pumpWidget(build(null));
    await tester.pump();
    await expectLater(
      find.byType(Lottie),
      matchesGoldenFile('goldens/dynamic_path_original.png'),
    );
  });
}
