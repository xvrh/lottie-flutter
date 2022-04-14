import 'dart:ui';

/// One cubic path operation. CubicCurveData is structured such that it is easy to iterate through
/// it and build a path. However, it is modeled differently than most path operations.
///
/// CubicCurveData
/// |                     - vertex
/// |                   /
/// |    cp1          cp2
/// |   /
/// |  |
/// | /
/// --------------------------
///
/// When incrementally building a path, it will already have a "current point" so that is
/// not captured in this data structure.
/// The control points here represent {@link android.graphics.Path#cubicTo(float, float, float, float, float, float)}.
///
/// Most path operations are centered around a vertex and its in control point and out control point like this:
/// |           outCp
/// |          /
/// |         |
/// |         v
/// |        /
/// |      inCp
/// --------------------------
class CubicCurveData {
  Offset controlPoint1 = Offset.zero;
  Offset controlPoint2 = Offset.zero;
  Offset vertex = Offset.zero;

  void setFrom(CubicCurveData curveData) {
    vertex = Offset(curveData.vertex.dx, curveData.vertex.dy);
    controlPoint1 =
        Offset(curveData.controlPoint1.dx, curveData.controlPoint1.dy);
    controlPoint2 =
        Offset(curveData.controlPoint2.dx, curveData.controlPoint2.dy);
  }

  @override
  String toString() {
    return 'v=$vertex cp1$controlPoint1 cp2=$controlPoint2';
  }
}
