import 'dart:typed_data';
import 'dart:ui';

class PathFactory {
  static Path create() {
    return Path();
  }
}

class FakePath implements Path {
  @override
  PathFillType fillType = PathFillType.nonZero;

  @override
  void addArc(Rect oval, double startAngle, double sweepAngle) {
    // TODO: implement addArc
  }

  @override
  void addOval(Rect oval) {
    // TODO: implement addOval
  }

  @override
  void addPath(Path path, Offset offset, {Float64List? matrix4}) {
    // TODO: implement addPath
  }

  @override
  void addPolygon(List<Offset> points, bool close) {
    // TODO: implement addPolygon
  }

  @override
  void addRRect(RRect rrect) {
    // TODO: implement addRRect
  }

  @override
  void addRect(Rect rect) {
    // TODO: implement addRect
  }

  @override
  void arcTo(
      Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    // TODO: implement arcTo
  }

  @override
  void arcToPoint(Offset arcEnd,
      {Radius radius = Radius.zero,
      double rotation = 0.0,
      bool largeArc = false,
      bool clockwise = true}) {
    // TODO: implement arcToPoint
  }

  @override
  void close() {
    // TODO: implement close
  }

  @override
  PathMetrics computeMetrics({bool forceClosed = false}) {
    // TODO: implement computeMetrics
    throw UnimplementedError();
  }

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    // TODO: implement conicTo
  }

  @override
  bool contains(Offset point) {
    // TODO: implement contains
    throw UnimplementedError();
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    // TODO: implement cubicTo
  }

  @override
  void extendWithPath(Path path, Offset offset, {Float64List? matrix4}) {
    // TODO: implement extendWithPath
  }

  @override
  Rect getBounds() {
    // TODO: implement getBounds
    throw UnimplementedError();
  }

  @override
  void lineTo(double x, double y) {
    // TODO: implement lineTo
  }

  @override
  void moveTo(double x, double y) {
    // TODO: implement moveTo
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    // TODO: implement quadraticBezierTo
  }

  @override
  void relativeArcToPoint(Offset arcEndDelta,
      {Radius radius = Radius.zero,
      double rotation = 0.0,
      bool largeArc = false,
      bool clockwise = true}) {
    // TODO: implement relativeArcToPoint
  }

  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    // TODO: implement relativeConicTo
  }

  @override
  void relativeCubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    // TODO: implement relativeCubicTo
  }

  @override
  void relativeLineTo(double dx, double dy) {
    // TODO: implement relativeLineTo
  }

  @override
  void relativeMoveTo(double dx, double dy) {
    // TODO: implement relativeMoveTo
  }

  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    // TODO: implement relativeQuadraticBezierTo
  }

  @override
  void reset() {
    // TODO: implement reset
  }

  @override
  Path shift(Offset offset) {
    // TODO: implement shift
    throw UnimplementedError();
  }

  @override
  Path transform(Float64List matrix4) {
    // TODO: implement transform
    throw UnimplementedError();
  }
}
