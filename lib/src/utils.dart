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
    return MatrixUtils.transformRect(this, rect);
  }

  /// Apply this matrix to the array of 2D points, and write the transformed points back into the
  /// array
  ///
  /// @param pts The array [x0, y0, x1, y1, ...] of points to transform.
  void mapPoints(List<double> array) {
    for (var i = 0; i < array.length; i += 2) {
      final v =
          MatrixUtils.transformPoint(this, Offset(array[i], array[i + 1]));

      array[i] = v.dx;
      array[i + 1] = v.dy;
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

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ListEquality<E> {
  static const int _hashMask = 0x7fffffff;

  const ListEquality();

  bool equals(List<E>? list1, List<E>? list2) {
    if (identical(list1, list2)) return true;
    if (list1 == null || list2 == null) return false;
    var length = list1.length;
    if (length != list2.length) return false;
    for (var i = 0; i < length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  int hash(List<E>? list) {
    if (list == null) return null.hashCode;
    // Jenkins's one-at-a-time hash function.
    // This code is almost identical to the one in IterableEquality, except
    // that it uses indexing instead of iterating to get the elements.
    var hash = 0;
    for (var i = 0; i < list.length; i++) {
      var c = list[i].hashCode;
      hash = (hash + c) & _hashMask;
      hash = (hash + (hash << 10)) & _hashMask;
      hash ^= hash >> 6;
    }
    hash = (hash + (hash << 3)) & _hashMask;
    hash ^= hash >> 11;
    hash = (hash + (hash << 15)) & _hashMask;
    return hash;
  }
}
