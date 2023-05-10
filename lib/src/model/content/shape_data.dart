import 'dart:math';
import 'dart:ui';
import '../cubic_curve_data.dart';

class ShapeData {
  final List<CubicCurveData> curves;
  Offset _initialPoint;
  bool isClosed;

  ShapeData(List<CubicCurveData> curves, {Offset? initialPoint, bool? closed})
      : curves = curves.toList(),
        _initialPoint = initialPoint ?? Offset.zero,
        isClosed = closed ?? false;

  ShapeData.empty() : this([]);

  void setInitialPoint(double x, double y) {
    _initialPoint = Offset(x, y);
  }

  Offset get initialPoint {
    return _initialPoint;
  }

  void interpolateBetween(
      ShapeData shapeData1, ShapeData shapeData2, double percentage) {
    isClosed = shapeData1.isClosed || shapeData2.isClosed;

    if (shapeData1.curves.length != shapeData2.curves.length) {
      // TODO(xha): decide what to do? We don't have access to the LottieDrawble
      // to emit the warning
      //logger.warning('Curves must have the same number of control points. '
      //    'Shape 1: ${shapeData1.curves.length}'
      //    '\tShape 2: ${shapeData2.curves.length}');
    }

    var points = min(shapeData1.curves.length, shapeData2.curves.length);
    if (curves.length < points) {
      for (var i = curves.length; i < points; i++) {
        curves.add(CubicCurveData());
      }
    } else if (curves.length > points) {
      for (var i = curves.length - 1; i >= points; i--) {
        curves.removeAt(curves.length - 1);
      }
    }

    var initialPoint1 = shapeData1.initialPoint;
    var initialPoint2 = shapeData2.initialPoint;

    setInitialPoint(lerpDouble(initialPoint1.dx, initialPoint2.dx, percentage)!,
        lerpDouble(initialPoint1.dy, initialPoint2.dy, percentage)!);

    for (var i = curves.length - 1; i >= 0; i--) {
      var curve1 = shapeData1.curves[i];
      var curve2 = shapeData2.curves[i];

      var cp11 = curve1.controlPoint1;
      var cp21 = curve1.controlPoint2;
      var vertex1 = curve1.vertex;

      var cp12 = curve2.controlPoint1;
      var cp22 = curve2.controlPoint2;
      var vertex2 = curve2.vertex;

      curves[i].controlPoint1 = Offset(
          lerpDouble(cp11.dx, cp12.dx, percentage)!,
          lerpDouble(cp11.dy, cp12.dy, percentage)!);
      curves[i].controlPoint2 = Offset(
          lerpDouble(cp21.dx, cp22.dx, percentage)!,
          lerpDouble(cp21.dy, cp22.dy, percentage)!);
      curves[i].vertex = Offset(lerpDouble(vertex1.dx, vertex2.dx, percentage)!,
          lerpDouble(vertex1.dy, vertex2.dy, percentage)!);
    }
  }

  @override
  String toString() {
    return 'ShapeData{'
        'numCurves=${curves.length}'
        'closed=$isClosed'
        '}';
  }
}
