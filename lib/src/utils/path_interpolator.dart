import 'dart:ui';
import 'package:flutter/animation.dart';

// ignore: must_be_immutable
class PathInterpolator extends Curve {
  /// Governs the accuracy of the approximation of the {@link Path}.
  static const double _precision = 0.002;

  late final List<double> _mX;
  late final List<double> _mY;
  bool _isInitialized = false;

  final double controlX1, controlY1, controlX2, controlY2;

  PathInterpolator.cubic(
      this.controlX1, this.controlY1, this.controlX2, this.controlY2);

  void _ensureInitialized() {
    if (_isInitialized) {
      return;
    }
    _initialize();
    _isInitialized = true;
  }

  void _initialize() {
    final path = Path();
    path.moveTo(0.0, 0.0);
    path.cubicTo(controlX1, controlY1, controlX2, controlY2, 1.0, 1.0);

    final pathMeasure = path.computeMetrics().toList().first;

    final pathLength = pathMeasure.length;
    final numPoints = (pathLength / _precision).round() + 1;

    var mX = List.filled(numPoints, 0.0);
    var mY = List.filled(numPoints, 0.0);

    for (var i = 0; i < numPoints; ++i) {
      final distance = (i * pathLength) / (numPoints - 1);
      var tangent = pathMeasure.getTangentForOffset(distance)!;

      mX[i] = tangent.position.dx;
      mY[i] = tangent.position.dy;
    }
    _mX = mX;
    _mY = mY;
  }

  @override
  double transform(double t) {
    _ensureInitialized();
    if (t <= 0.0) {
      return 0.0;
    } else if (t >= 1.0) {
      return 1.0;
    }

    // Do a binary search for the correct x to interpolate between.
    var startIndex = 0;
    var endIndex = _mX.length - 1;
    while (endIndex - startIndex > 1) {
      var midIndex = ((startIndex + endIndex) / 2).round();
      if (t < _mX[midIndex]) {
        endIndex = midIndex;
      } else {
        startIndex = midIndex;
      }
    }

    final xRange = _mX[endIndex] - _mX[startIndex];
    if (xRange == 0) {
      return _mY[startIndex];
    }

    final tInRange = t - _mX[startIndex];
    final fraction = tInRange / xRange;

    final startY = _mY[startIndex];
    final endY = _mY[endIndex];

    return startY + (fraction * (endY - startY));
  }
}
