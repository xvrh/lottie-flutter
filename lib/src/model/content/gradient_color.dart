import 'dart:ui';
import '../../utils.dart';
import '../../utils/collection.dart';
import '../../utils/gamma_evaluator.dart';

// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

class GradientColor {
  final List<double> positions;
  final List<Color> colors;

  const GradientColor(this.positions, this.colors);

  int get size => colors.length;

  void lerp(GradientColor gc1, GradientColor gc2, double progress) {
    // Fast return in case start and end is the same
    // or if progress is at start/end or out of [0,1] bounds
    if (gc1 == gc2) {
      _copyFrom(gc1);
      return;
    } else if (progress <= 0) {
      _copyFrom(gc1);
      return;
    } else if (progress >= 1) {
      _copyFrom(gc2);
      return;
    }

    if (gc1.colors.length != gc2.colors.length) {
      throw Exception('Cannot interpolate between gradients. '
          'Lengths vary (${gc1.colors.length} vs ${gc2.colors.length})');
    }

    for (var i = 0; i < gc1.colors.length; i++) {
      positions[i] = lerpDouble(gc1.positions[i], gc2.positions[i], progress)!;
      colors[i] =
          GammaEvaluator.evaluate(progress, gc1.colors[i], gc2.colors[i]);
    }
    // Not all keyframes that this GradientColor are used for will have the same length.
    // AnimatableGradientColorValue.ensureInterpolatableKeyframes may add extra positions
    // for some keyframes but not others to ensure that it is interpolatable.
    // If there are extra positions here, just duplicate the last value in the gradient.
    for (var i = gc1.colors.length; i < positions.length; i++) {
      positions[i] = positions[gc1.colors.length - 1];
      colors[i] = colors[gc1.colors.length - 1];
    }
  }

  GradientColor copyWithPositions(List<double> positions) {
    var colors = List<Color>.filled(positions.length, const Color(0x00000000));
    for (var i = 0; i < positions.length; i++) {
      colors[i] = _getColorForPosition(positions[i]);
    }
    return GradientColor(positions, colors);
  }

  Color _getColorForPosition(double position) {
    var existingIndex = binarySearch(positions, position);
    if (existingIndex >= 0) {
      return colors[existingIndex];
    }
    // binarySearch returns -insertionPoint - 1 if it is not found.
    var insertionPoint = -(existingIndex + 1);
    if (insertionPoint == 0) {
      return colors[0];
    } else if (insertionPoint == colors.length - 1) {
      return colors[colors.length - 1];
    }
    var startPosition = positions[insertionPoint - 1];
    var endPosition = positions[insertionPoint];
    var startColor = colors[insertionPoint - 1];
    var endColor = colors[insertionPoint];

    var fraction = (position - startPosition) / (endPosition - startPosition);
    return GammaEvaluator.evaluate(fraction, startColor, endColor);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! GradientColor) {
      return false;
    }
    return const ListEquality<double>().equals(positions, other.positions) &&
        const ListEquality<Color>().equals(colors, other.colors);
  }

  @override
  int get hashCode {
    var result = Object.hashAll(positions);
    result = 31 * result + Object.hashAll(colors);
    return result;
  }

  void _copyFrom(GradientColor other) {
    for (var i = 0; i < other.colors.length; i++) {
      positions[i] = other.positions[i];
      colors[i] = other.colors[i];
    }
  }
}
