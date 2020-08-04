import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('Frame rate round', () async {
    var composition = await LottieComposition.fromBytes(
        File('example/assets/LottieLogo1.json').readAsBytesSync());
    expect(composition.roundProgress(0, frameRate: FrameRate.composition), 0);
    expect(
        composition.roundProgress(0.0001, frameRate: FrameRate.composition), 0);
    expect(composition.roundProgress(0.0001, frameRate: FrameRate.max), 0.0001);
  });
}
