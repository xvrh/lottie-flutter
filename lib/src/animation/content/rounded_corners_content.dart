import 'dart:math' as math;
import 'dart:ui';
import '../../lottie_drawable.dart';
import '../../model/content/rounded_corners.dart';
import '../../model/content/shape_data.dart';
import '../../model/cubic_curve_data.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../utils/misc.dart';
import '../keyframe/base_keyframe_animation.dart';
import 'content.dart';
import 'shape_modifier_content.dart';

class RoundedCornersContent implements ShapeModifierContent {
  /// Copied from:
  /// https://github.com/airbnb/lottie-web/blob/bb71072a26e03f1ca993da60915860f39aae890b/player/js/utils/common.js#L47
  static const _roundedCornerMagicNumber = 0.5519;

  final LottieDrawable lottieDrawable;

  @override
  final String name;
  final BaseKeyframeAnimation<double, double> roundedCorners;
  ShapeData? shapeData;

  RoundedCornersContent(
      this.lottieDrawable, BaseLayer layer, RoundedCorners roundedCorners)
      : name = roundedCorners.name,
        roundedCorners = roundedCorners.cornerRadius.createAnimation() {
    layer.addAnimation(this.roundedCorners);
    this.roundedCorners.addUpdateListener(_onValueChanged);
  }

  void _onValueChanged() {
    lottieDrawable.invalidateSelf();
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    // Do nothing.
  }

  /// Rounded corner algorithm:
  /// Iterate through each vertex.
  /// If a vertex is a sharp corner, it rounds it.
  /// If a vertex has control points, it is already rounded, so it does nothing.
  /// <p>
  /// To round a vertex:
  /// Split the vertex into two.
  /// Move vertex 1 directly towards the previous vertex.
  /// Set vertex 1's in control point to itself so it is not rounded on that side.
  /// Extend vertex 1's out control point towards the original vertex.
  /// <p>
  /// Repeat for vertex 2:
  /// Move vertex 2 directly towards the next vertex.
  /// Set vertex 2's out point to itself so it is not rounded on that side.
  /// Extend vertex 2's in control point towards the original vertex.
  /// <p>
  /// The distance that the vertices and control points are moved are relative to the
  /// shape's vertex distances and the roundedness set in the animation.
  @override
  ShapeData modifyShape(ShapeData startingShapeData) {
    var startingCurves = startingShapeData.curves;
    if (startingCurves.length <= 2) {
      return startingShapeData;
    }
    var roundedness = roundedCorners.value;
    if (roundedness == 0) {
      return startingShapeData;
    }

    var modifiedShapeData = _getShapeData(startingShapeData);
    modifiedShapeData.setInitialPoint(
        startingShapeData.initialPoint.dx, startingShapeData.initialPoint.dy);
    var modifiedCurves = modifiedShapeData.curves;
    var modifiedCurvesIndex = 0;
    var isClosed = startingShapeData.isClosed;

    // i represents which vertex we are currently on. Refer to the docs of CubicCurveData prior to working with
    // this code.
    // When i == 0
    //    vertex=ShapeData.initialPoint
    //    inCp=if closed vertex else curves[size - 1].cp2
    //    outCp=curves[0].cp1
    // When i == 1
    //    vertex=curves[0].vertex
    //    inCp=curves[0].cp2
    //    outCp=curves[1].cp1.
    // When i == size - 1
    //    vertex=curves[size - 1].vertex
    //    inCp=curves[size - 1].cp2
    //    outCp=if closed vertex else curves[0].cp1
    for (var i = 0; i < startingCurves.length; i++) {
      var startingCurve = startingCurves[i];
      var previousCurve =
          startingCurves[floorMod(i - 1, startingCurves.length)];
      var previousPreviousCurve =
          startingCurves[floorMod(i - 2, startingCurves.length)];
      var vertex = (i == 0 && !isClosed)
          ? startingShapeData.initialPoint
          : previousCurve.vertex;
      var inPoint =
          (i == 0 && !isClosed) ? vertex : previousCurve.controlPoint2;
      var outPoint = startingCurve.controlPoint1;
      var previousVertex = previousPreviousCurve.vertex;
      var nextVertex = startingCurve.vertex;

      // We can't round the corner of the end of a non-closed curve.
      var isEndOfCurve = !startingShapeData.isClosed &&
          (i == 0 || i == startingCurves.length - 1);
      if (inPoint == vertex && outPoint == vertex && !isEndOfCurve) {
        // This vertex is a point. Round its corners
        var dxToPreviousVertex = vertex.dx - previousVertex.dx;
        var dyToPreviousVertex = vertex.dy - previousVertex.dy;
        var dxToNextVertex = nextVertex.dx - vertex.dx;
        var dyToNextVertex = nextVertex.dy - vertex.dy;

        var dToPreviousVertex = hypot(dxToPreviousVertex, dyToPreviousVertex);
        var dToNextVertex = hypot(dxToNextVertex, dyToNextVertex);

        double previousVertexPercent =
            math.min(roundedness / dToPreviousVertex, 0.5);
        double nextVertexPercent = math.min(roundedness / dToNextVertex, 0.5);

        // Split the vertex into two and move each vertex towards the previous/next vertex.
        var newVertex1X =
            vertex.dx + (previousVertex.dx - vertex.dx) * previousVertexPercent;
        var newVertex1Y =
            vertex.dy + (previousVertex.dy - vertex.dy) * previousVertexPercent;
        var newVertex2X =
            vertex.dx + (nextVertex.dx - vertex.dx) * nextVertexPercent;
        var newVertex2Y =
            vertex.dy + (nextVertex.dy - vertex.dy) * nextVertexPercent;

        // Extend the new vertex control point towards the original vertex.
        var newVertex1OutPointX =
            newVertex1X - (newVertex1X - vertex.dx) * _roundedCornerMagicNumber;
        var newVertex1OutPointY =
            newVertex1Y - (newVertex1Y - vertex.dy) * _roundedCornerMagicNumber;
        var newVertex2InPointX =
            newVertex2X - (newVertex2X - vertex.dx) * _roundedCornerMagicNumber;
        var newVertex2InPointY =
            newVertex2Y - (newVertex2Y - vertex.dy) * _roundedCornerMagicNumber;

        // Remap vertex/in/out point to CubicCurveData.
        // Refer to the docs for CubicCurveData for more info on the difference.
        var previousCurveData = modifiedCurves[
            floorMod(modifiedCurvesIndex - 1, modifiedCurves.length)];
        var currentCurveData = modifiedCurves[modifiedCurvesIndex];
        previousCurveData.controlPoint2 = Offset(newVertex1X, newVertex1Y);
        previousCurveData.vertex = Offset(newVertex1X, newVertex1Y);
        if (i == 0) {
          modifiedShapeData.setInitialPoint(newVertex1X, newVertex1Y);
        }
        currentCurveData.controlPoint1 =
            Offset(newVertex1OutPointX, newVertex1OutPointY);
        modifiedCurvesIndex++;

        previousCurveData = currentCurveData;
        currentCurveData = modifiedCurves[modifiedCurvesIndex];
        previousCurveData.controlPoint2 =
            Offset(newVertex2InPointX, newVertex2InPointY);
        previousCurveData.vertex = Offset(newVertex2X, newVertex2Y);
        currentCurveData.controlPoint1 = Offset(newVertex2X, newVertex2Y);
        modifiedCurvesIndex++;
      } else {
        // This vertex is not a point. Don't modify it. Refer to the documentation above and for CubicCurveData for mapping a vertex
        // oriented point to CubicCurveData (path segments).
        var previousCurveData = modifiedCurves[
            floorMod(modifiedCurvesIndex - 1, modifiedCurves.length)];
        var currentCurveData = modifiedCurves[modifiedCurvesIndex];
        previousCurveData.controlPoint2 = Offset(
            previousCurve.controlPoint2.dx, previousCurve.controlPoint2.dy);
        previousCurveData.vertex =
            Offset(previousCurve.vertex.dx, previousCurve.vertex.dy);
        currentCurveData.controlPoint1 = Offset(
            startingCurve.controlPoint1.dx, startingCurve.controlPoint1.dy);
        modifiedCurvesIndex++;
      }
    }
    return modifiedShapeData;
  }

  /// Returns a shape data with the correct number of vertices for the rounded corners shape.
  /// This just returns the object. It does not update any values within the shape.

  ShapeData _getShapeData(ShapeData startingShapeData) {
    var startingCurves = startingShapeData.curves;
    var isClosed = startingShapeData.isClosed;
    var vertices = 0;
    for (var i = startingCurves.length - 1; i >= 0; i--) {
      var startingCurve = startingCurves[i];
      var previousCurve =
          startingCurves[floorMod(i - 1, startingCurves.length)];
      var vertex = (i == 0 && !isClosed)
          ? startingShapeData.initialPoint
          : previousCurve.vertex;
      var inPoint =
          (i == 0 && !isClosed) ? vertex : previousCurve.controlPoint2;
      var outPoint = startingCurve.controlPoint1;

      var isEndOfCurve = !startingShapeData.isClosed &&
          (i == 0 || i == startingCurves.length - 1);
      if (inPoint == vertex && outPoint == vertex && !isEndOfCurve) {
        vertices += 2;
      } else {
        vertices += 1;
      }
    }
    var shapeData = this.shapeData;
    if (shapeData == null || shapeData.curves.length != vertices) {
      var newCurves = <CubicCurveData>[];
      for (var i = 0; i < vertices; i++) {
        newCurves.add(CubicCurveData());
      }
      this.shapeData = shapeData =
          ShapeData(newCurves, initialPoint: Offset.zero, closed: false);
    }
    shapeData.isClosed = isClosed;
    return shapeData;
  }

  static int floorMod(int x, int y) => MiscUtils.floorModInt(x, y);
}
