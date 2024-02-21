import 'dart:ui';
import '../animation/content/key_path_element_content.dart';
import '../model/content/shape_data.dart';
import '../model/key_path.dart';

class MiscUtils {
  static void getPathFromData(ShapeData shapeData, Path outPath) {
    outPath.reset();
    var initialPoint = shapeData.initialPoint;
    outPath.moveTo(initialPoint.dx, initialPoint.dy);
    var currentPoint = initialPoint;

    for (var i = 0; i < shapeData.curves.length; i++) {
      var curveData = shapeData.curves[i];
      var cp1 = curveData.controlPoint1;
      var cp2 = curveData.controlPoint2;
      var vertex = curveData.vertex;

      if (cp1 == currentPoint && cp2 == vertex) {
        // On some phones like Samsung phones, zero valued control points can cause artifacting.
        // https://github.com/airbnb/lottie-android/issues/275
        //
        // This does its best to add a tiny value to the vertex without affecting the final
        // animation as much as possible.
        // outPath.rMoveTo(0.01f, 0.01f);
        outPath.lineTo(vertex.dx, vertex.dy);
      } else {
        outPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, vertex.dx, vertex.dy);
      }
      currentPoint = vertex;
    }
    if (shapeData.isClosed) {
      outPath.close();
    }
  }

  static bool isAtLeastVersion(int major, int minor, int patch, int minMajor,
      int minMinor, int minPatch) {
    if (major < minMajor) {
      return false;
    } else if (major > minMajor) {
      return true;
    }

    if (minor < minMinor) {
      return false;
    } else if (minor > minMinor) {
      return true;
    }

    return patch >= minPatch;
  }

  static Color parseColor(String colorString,
      {required void Function(String) warningCallback}) {
    if (colorString.isNotEmpty && colorString[0] == '#') {
      // Use a long to avoid rollovers on #ffXXXXXX
      var color = int.parse(colorString.substring(1), radix: 16);
      if (colorString.length == 7) {
        // Set the alpha value
        color |= 0x00000000ff000000;
      } else if (colorString.length != 9) {
        warningCallback('Unknown color colorString: $colorString');
        return const Color(0xffffffff);
      }
      return Color(color);
    }
    warningCallback(
        'Unknown colorString is empty or format incorrect: $colorString');
    return const Color(0xffffffff);
  }

  static int floorMod(double x, double y) {
    var xInt = x.toInt();
    var yInt = y.toInt();
    return xInt - yInt * _floorDiv(xInt, yInt);
  }

  static int floorModInt(int x, int y) {
    return x - y * _floorDiv(x, y);
  }

  static int _floorDiv(int x, int y) {
    var r = x ~/ y;
    var sameSign = x.sign == y.sign;

    var mod = x % y;
    if (!sameSign && mod != 0) {
      r--;
    }
    return r;
  }

  /// Helper method for any {@link KeyPathElementContent} that will check if the content
  /// fully matches the keypath then will add itself as the final key, resolve it, and add
  /// it to the accumulator list.
  ///
  /// Any {@link KeyPathElementContent} should call through to this as its implementation of
  /// {KeyPathElementContent#resolveKeyPath(KeyPath, int, List, KeyPath)}.
  static void resolveKeyPath(
      KeyPath keyPath,
      int depth,
      List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath,
      KeyPathElementContent content) {
    if (keyPath.fullyResolvesTo(content.name, depth)) {
      currentPartialKeyPath = currentPartialKeyPath.addKey(content.name!);
      accumulator.add(currentPartialKeyPath.resolve(content));
    }
  }
}
