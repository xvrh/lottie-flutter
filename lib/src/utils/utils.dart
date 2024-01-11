import 'dart:math';
import 'dart:ui';
import '../animation/content/trim_path_content.dart';
import '../l.dart';
import '../utils.dart';
import 'misc.dart';

class Utils {
  static Path createPath(
      Offset startPoint, Offset endPoint, Offset? cp1, Offset? cp2) {
    var path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    if (cp1 != null &&
        cp2 != null &&
        (cp1.distance != 0 || cp2.distance != 0)) {
      path.cubicTo(startPoint.dx + cp1.dx, startPoint.dy + cp1.dy,
          endPoint.dx + cp2.dx, endPoint.dy + cp2.dy, endPoint.dx, endPoint.dy);
    } else {
      path.lineTo(endPoint.dx, endPoint.dy);
    }
    return path;
  }

  static int hashFor(double a, double b, double c, double d) {
    var result = 17;
    if (a != 0) {
      result = (31 * result * a).round();
    }
    if (b != 0) {
      result = (31 * result * b).round();
    }
    if (c != 0) {
      result = (31 * result * c).round();
    }
    if (d != 0) {
      result = (31 * result * d).round();
    }
    return result;
  }

  static void applyTrimPathContentIfNeeded(
      Path path, TrimPathContent? trimPath) {
    if (trimPath == null || trimPath.hidden) {
      return;
    }
    var start = trimPath.start.value;
    var end = trimPath.end.value;
    var offset = trimPath.offset.value;
    applyTrimPathIfNeeded(path, start / 100.0, end / 100.0, offset / 360.0);
  }

  static void applyTrimPathIfNeeded(
      Path path, double startValue, double endValue, double offsetValue) {
    L.beginSection('applyTrimPathIfNeeded');
    var metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) {
      L.endSection('applyTrimPathIfNeeded');
      return;
    }

    var pathMeasure = metrics.first;

    if (startValue == 1.0 && endValue == 0.0) {
      L.endSection('applyTrimPathIfNeeded');
      return;
    }
    var length = pathMeasure.length;
    if (length < 1.0 || (endValue - startValue - 1).abs() < .01) {
      L.endSection('applyTrimPathIfNeeded');
      return;
    }
    var start = length * startValue;
    var end = length * endValue;
    var newStart = min(start, end);
    var newEnd = max(start, end);

    var offset = offsetValue * length;
    newStart += offset;
    newEnd += offset;

    // If the trim path has rotated around the path, we need to shift it back.
    if (newStart >= length && newEnd >= length) {
      newStart = MiscUtils.floorMod(newStart, length).toDouble();
      newEnd = MiscUtils.floorMod(newEnd, length).toDouble();
    }

    if (newStart < 0) {
      newStart = MiscUtils.floorMod(newStart, length).toDouble();
    }
    if (newEnd < 0) {
      newEnd = MiscUtils.floorMod(newEnd, length).toDouble();
    }

    // If the start and end are equals, return an empty path.
    if (newStart == newEnd) {
      path.reset();
      L.endSection('applyTrimPathIfNeeded');
      return;
    }

    if (newStart >= newEnd) {
      newStart -= length;
    }

    var tempPath = pathMeasure.extractPath(newStart, newEnd);

    if (newEnd > length) {
      var tempPath2 = pathMeasure.extractPath(0, newEnd % length);
      tempPath.addPath(tempPath2, Offset.zero);
    } else if (newStart < 0) {
      var tempPath2 = pathMeasure.extractPath(length + newStart, length);
      tempPath.addPath(tempPath2, Offset.zero);
    }
    path.set(tempPath);
    L.endSection('applyTrimPathIfNeeded');
  }
}
