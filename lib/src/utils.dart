import 'dart:math';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

extension PaintExtension on Paint {
  void setAlpha(int alpha) {
    color = color.withAlpha(alpha);
  }
}

extension PathExtension on Path {
  void set(Path path) {
    reset();
    addPath(path, Offset.zero);
  }

  void offset(Offset offset) {
    set(shift(offset));
  }
}

extension Matrix4Extension on Matrix4 {
  void preConcat(Matrix4 matrix) {
    multiply(matrix);
  }

  void reset() {
    setIdentity();
  }

  void set(Matrix4 matrix) {
    matrix.copyInto(this);
  }

  Rect mapRect(Rect rect) {
    var topLeft = Vector3(rect.left, rect.top, 0.0)..applyMatrix4(this);
    var topRight = Vector3(rect.right, rect.top, 0.0)..applyMatrix4(this);
    var bottomLeft = Vector3(rect.left, rect.bottom, 0.0)..applyMatrix4(this);
    var bottomRight = Vector3(rect.right, rect.bottom, 0.0)..applyMatrix4(this);

    var newLeft = min(topLeft.x, bottomLeft.x);
    var newTop = min(topLeft.y, topRight.y);
    var newRight = max(topRight.x, bottomRight.x);
    var newBottom = max(bottomLeft.y, bottomRight.y);

    return Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
  }

  /// Apply this matrix to the array of 2D points, and write the transformed points back into the
  /// array
  ///
  /// @param pts The array [x0, y0, x1, y1, ...] of points to transform.
  void mapPoints(List<double> array, [int offset]) {
    for (var i = 0; i < array.length; i += 2) {
      final v = Vector3(array[i], array[i + 1], 0.0)..applyMatrix4(this);
      array[i] = v.storage[0];
      array[i + 1] = v.storage[1];
    }
  }

  double getScale() {
    var p0 = Vector3(0, 0, 0)..applyMatrix4(this);
    var p1 = Vector3(1 / sqrt(2), 1 / sqrt(2), 0)..applyMatrix4(this);

    var dx = p1.x - p0.x;
    var dy = p1.y - p0.y;

    return hypot(dx, dy).toDouble();
  }

  bool get hasZeroScaleAxis {
    var p0 = Vector3(0, 0, 0)..applyMatrix4(this);
    // Random numbers. The only way these should map to the same thing as 0,0 is if the scale is 0.
    var p1 = Vector3(37394.729378, 39575.2343807, 0)..applyMatrix4(this);

    return p0.x == p1.x || p0.y == p1.y;
  }
}

extension OffsetExtension on Offset {
  bool get isZero => dx == 0 && dy == 0;
}

num hypot(num x, num y) {
  return sqrt(x * x + y * y);
}
