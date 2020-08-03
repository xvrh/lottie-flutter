import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/render_lottie.dart';

void main() {
  test('Frame rate round', () async {
    var composition = await LottieComposition.fromBytes(
        File('example/assets/LottieLogo1.json').readAsBytesSync());
    expect(composition.roundProgress(0, frameRate: FrameRate.composition), 0);
    expect(
        composition.roundProgress(0.0001, frameRate: FrameRate.composition), 0);
    expect(composition.roundProgress(0.0001, frameRate: FrameRate.max), 0.0001);
  });

  testWidgets('Animation not painted if not needed', (tester) async {
    var composition = await tester.runAsync(() => LottieComposition.fromBytes(
        File('example/assets/LottieLogo1.json').readAsBytesSync()));

    await tester.pumpWidget(Lottie(
      composition: composition,
      animate: false,
    ));

    await tester.pump();
  });
}
