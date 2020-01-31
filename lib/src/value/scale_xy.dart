import 'dart:ui';

//TODO(xha): delete and use Offset
class ScaleXY {
  final double x;
  final double y;

  ScaleXY(this.x, this.y);
  ScaleXY.one() : this(1, 1);

  @override
  bool operator ==(other) {
    return other is ScaleXY && x == other.x && y == other.y;
  }

  @override
  int get hashCode => hashValues(x, y);

  bool equals(double x, double y) => this.x == x && this.y == y;

  static ScaleXY lerp(ScaleXY a, ScaleXY b, double t) =>
      ScaleXY(lerpDouble(a.x, b.x, t), lerpDouble(a.y, b.y, t));
}
