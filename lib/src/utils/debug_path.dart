import 'dart:typed_data';
import 'dart:ui';

class DebugPath extends Path {
  void _log(String methodName) {
    print('Path.$methodName');
  }

  @override
  void addArc(Rect oval, double startAngle, double sweepAngle) {
    _log('addArc');
    super.addArc(oval, startAngle, sweepAngle);
  }

  @override
  void addOval(Rect oval) {
    _log('addOval');
    super.addOval(oval);
  }

  @override
  void addPath(Path path, Offset offset, {Float64List? matrix4}) {
    _log('addPath');
    super.addPath(path, offset, matrix4: matrix4);
  }

  @override
  void addPolygon(List<Offset> points, bool close) {
    _log('addPolygon');
    super.addPolygon(points, close);
  }

  @override
  void addRRect(RRect rrect) {
    _log('addRRect');
    super.addRRect(rrect);
  }

  @override
  void addRect(Rect rect) {
    _log('addRect');
    super.addRect(rect);
  }

  @override
  void arcTo(
      Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    _log('arcTo');
    super.arcTo(rect, startAngle, sweepAngle, forceMoveTo);
  }

  @override
  void arcToPoint(Offset arcEnd,
      {Radius radius = Radius.zero,
      double rotation = 0.0,
      bool largeArc = false,
      bool clockwise = true}) {
    _log('arcToPoint');
    super.arcToPoint(arcEnd,
        radius: radius,
        rotation: rotation,
        largeArc: largeArc,
        clockwise: clockwise);
  }

  @override
  void close() {
    _log('close');
    super.close();
  }

  @override
  PathMetrics computeMetrics({bool forceClosed = false}) {
    _log('computeMetrics');
    return super.computeMetrics();
  }

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    _log('conicTo');
    super.conicTo(x1, y1, x2, y2, w);
  }

  @override
  bool contains(Offset point) {
    _log('contains');
    return super.contains(point);
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _log('cubicTo');
    super.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void extendWithPath(Path path, Offset offset, {Float64List? matrix4}) {
    _log('extendWithPath');
    super.extendWithPath(path, offset, matrix4: matrix4);
  }

  @override
  Rect getBounds() {
    _log('getBounds');
    return super.getBounds();
  }

  @override
  void lineTo(double x, double y) {
    _log('lineTo');
    super.lineTo(x, y);
  }

  @override
  void moveTo(double x, double y) {
    _log('moveTo');
    super.moveTo(x, y);
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    _log('quadraticBezierTo');
    super.quadraticBezierTo(x1, y1, x2, y2);
  }

  @override
  void relativeArcToPoint(Offset arcEndDelta,
      {Radius radius = Radius.zero,
      double rotation = 0.0,
      bool largeArc = false,
      bool clockwise = true}) {
    _log('relativeArcToPoint');
    super.relativeArcToPoint(arcEndDelta,
        radius: radius,
        rotation: rotation,
        largeArc: largeArc,
        clockwise: clockwise);
  }

  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    _log('relativeConicTo');
    super.relativeConicTo(x1, y1, x2, y2, w);
  }

  @override
  void relativeCubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _log('relativeCubicTo');
    super.relativeCubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void relativeLineTo(double dx, double dy) {
    _log('relativeLineTo');
    super.relativeLineTo(dx, dy);
  }

  @override
  void relativeMoveTo(double dx, double dy) {
    _log('relativeMoveTo');
    super.relativeMoveTo(dx, dy);
  }

  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    _log('relativeQuadraticBezierTo');
    super.relativeQuadraticBezierTo(x1, y1, x2, y2);
  }

  @override
  void reset() {
    _log('reset');
    super.reset();
  }

  @override
  Path shift(Offset offset) {
    _log('shift');
    return super.shift(offset);
  }

  @override
  Path transform(Float64List matrix4) {
    _log('transform');
    return super.transform(matrix4);
  }
}
