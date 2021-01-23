import 'dart:ui';
import '../../utils/gamma_evaluator.dart';

class GradientColor {
  final List<double> positions;
  final List<Color> colors;

  GradientColor(this.positions, this.colors);

  int get size => colors.length;

  void lerp(GradientColor gc1, GradientColor gc2, double progress) {
    if (gc1.colors.length != gc2.colors.length) {
      throw Exception('Cannot interpolate between gradients. '
          'Lengths vary (${gc1.colors.length} vs ${gc2.colors.length})');
    }

    for (var i = 0; i < gc1.colors.length; i++) {
      positions[i] = lerpDouble(gc1.positions[i], gc2.positions[i], progress)!;
      colors[i] =
          GammaEvaluator.evaluate(progress, gc1.colors[i], gc2.colors[i]);
    }
  }
}
