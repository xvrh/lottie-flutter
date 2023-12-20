import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import 'content.dart';

abstract class DrawingContent extends Content {
  void draw(Canvas canvas, Matrix4 parentMatrix, {required int parentAlpha});
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents});
}
