import 'package:flutter/cupertino.dart';

import '../../lottie.dart';
import '../animation/content/drawing_content.dart';
import '../animation/content/stroke_content.dart';
import '../model/key_path.dart';
import '../model/lottie_observer.dart';
import '../utils.dart';

class LottieApi {
  final LottieDrawable drawable;

  LottieApi(this.drawable);

  List<KeyPath> _resolveKeyPath(final List<String> keyPath) {
    final layer = drawable.compositionLayer;
    var keyPaths = <KeyPath>[];
    layer.resolveKeyPath(KeyPath(keyPath), 0, keyPaths, KeyPath([]));
    return keyPaths;
  }

  /// converts points from global animation coordinates to property animation coordinates
  ///
  ///  * [keyPath], Key Path array such as ["Loop","left_eye","Group 10"].
  ///  * [points], Global coordinates.
  ///
  List<Offset> _toKeyPathLayerPoints(
      final List<String> keyPath, final List<Offset> points) {
    var transPoints = <Offset>[];
    var keyPaths = _resolveKeyPath(keyPath);
    for (var i = 0; i < keyPaths.length; i++) {
      var kp = keyPaths[i];
      var element = kp.resolvedElement;
      if (null != element) {
        var matrix = Matrix4.identity();
        if (element is LottieObserver) {
          var observer = element as LottieObserver;
          observer.applyToMatrix(matrix);
          var hierarchy = observer.requireMatrixHierarchy();
          for (var i = 0; i < hierarchy.length; i++) {
            hierarchy[i].applyToMatrix(matrix);
          }
        }
        for (var j = 0; j < points.length; j++) {
          var point = points[j];
          var trans = matrix.inversePoint(point);
          transPoints.add(trans);
        }
      }
    }
    return transPoints;
  }

  /// converts a point from global animation coordinates to property animation coordinates
  ///
  ///  * [keyPath], Key Path array such as ["Loop","left_eye","Group 10"].
  ///  * [raw], Global coordinates.
  ///
  List<Offset> toKeyPathLayerPoint(
      final List<String> keyPath, final Offset raw) {
    if (keyPath.isEmpty) {
      return [];
    }
    var points = <Offset>[raw];
    for (var i = 1; i <= keyPath.length; i++) {
      var lp = _toKeyPathLayerPoints(keyPath.sublist(0, i), points);
      if (lp.isEmpty) {
        points = [];
      }
      points = lp;
    }
    return points;
  }

  ///   converts a point from animation coordinates to global coordinates
  ///
  ///  * [point], animation coordinates point.
  ///
  Offset toContainerPoint(final Offset point) {
    var bounds = drawable.drawBounds;
    var offset = drawable.topLeft;
    var newPoint = Offset(
        point.dx - bounds.left - offset.dx, point.dy - bounds.top - offset.dy);
    var matrix = drawable.matrix;
    var scale = matrix.getScale();
    newPoint = newPoint * (1.0 / scale);
    return newPoint;
  }

  List<ValueDelegate> requireColorValueDelegates(
      final List<String> keyPath, final ValueNotifier<Color> color) {
    var delegates = <ValueDelegate>[];
    var keyPaths = _resolveKeyPath(keyPath);
    for (var i = 0; i < keyPaths.length; i++) {
      var value = keyPaths[i];
      var element = value.resolvedElement;
      if (element is StrokeContent) {
        var delegate = ValueDelegate.strokeColor(keyPath, callback: (cb) {
          return color.value;
        });
        delegates.add(delegate);
      } else if (element is DrawingContent) {
        var delegate = ValueDelegate.color(keyPath, callback: (cb) {
          return color.value;
        });
        delegates.add(delegate);
      }
    }
    return delegates;
  }

  ///   check if the hit on Key Path
  ///  * [keyPath], Key Path array such as ["Loop","left_eye","Group 10"].
  ///  * [point], hit point.
  ///
  bool hitTest(final List<String> keyPath, final Offset point) {
    var bounds = drawable.drawBounds;
    if (!bounds.contains(point)) {
      return false;
    }
    var hitPoint = point - drawable.topLeft;
    var keyPaths = _resolveKeyPath(keyPath);
    for (var i = 0; i < keyPaths.length; i++) {
      var value = keyPaths[i];
      var element = value.resolvedElement;
      if (element is LottieObserver) {
        var observer = element! as LottieObserver;
        if (observer.hitTest(hitPoint)) {
          return true;
        }
      }
    }
    return false;
  }
}
