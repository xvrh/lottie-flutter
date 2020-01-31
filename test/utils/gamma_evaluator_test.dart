import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/utils/gamma_evaluator.dart';

void main() {
  test('Evaluate for same color values', () {
    for (var color = 0x000000; color <= 0xffffff; color++) {
      var colorToTest = Color(0xff000000 | color);
      var actual = GammaEvaluator.evaluate(0.3, colorToTest, colorToTest);
      expect(actual, colorToTest);
    }
  });
}
