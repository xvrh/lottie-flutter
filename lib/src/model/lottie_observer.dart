import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

abstract class LottieObserver {
  void applyToMatrix(final Matrix4 matrix);

  List<LottieObserver> requireMatrixHierarchy();

  /// Determines the objects located at the given position.
  ///
  /// Returns true, if this object absorbs the hit.
  /// Returns false, if the hit can continue to other objects .
  bool hitTest(final Offset position);
}
