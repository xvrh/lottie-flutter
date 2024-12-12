import 'dart:ui';
import '../model/content/gradient_color.dart';
import '../utils/collection.dart';
import '../utils/gamma_evaluator.dart';
import 'moshi/json_reader.dart';

class GradientColorParser {
  /// The number of colors if it exists in the json or -1 if it doesn't (legacy bodymovin)
  int _colorPoints;

  GradientColorParser(this._colorPoints);

  /// Both the color stops and opacity stops are in the same array.
  /// There are {@link #colorPoints} colors sequentially as:
  /// [
  /// ...,
  /// position,
  /// red,
  /// green,
  /// blue,
  /// ...
  /// ]
  /// <p>
  /// The remainder of the array is the opacity stops sequentially as:
  /// [
  /// ...,
  /// position,
  /// opacity,
  /// ...
  /// ]
  GradientColor parse(JsonReader reader) {
    var array = <double>[];
    // The array was started by Keyframe because it thought that this may be an array of keyframes
    // but peek returned a number so it considered it a static array of numbers.
    var isArray = reader.peek() == Token.beginArray;
    if (isArray) {
      reader.beginArray();
    }
    while (reader.hasNext()) {
      array.add(reader.nextDouble());
    }
    if (array.length == 4 && array[0] == 1) {
      // If a gradient color only contains one color at position 1, add a second stop with the same
      // color at position 0. Android's LinearGradient shader requires at least two colors.
      // https://github.com/airbnb/lottie-android/issues/1967
      array[0] = 0;
      array.add(1);
      array.add(array[1]);
      array.add(array[2]);
      array.add(array[3]);
      _colorPoints = 2;
    }
    if (isArray) {
      reader.endArray();
    }
    if (_colorPoints == -1) {
      _colorPoints = array.length ~/ 4;
    }

    var positions = List<double>.filled(_colorPoints, 0.0);
    var colors = List<Color>.filled(_colorPoints, const Color(0x00000000));

    var r = 0;
    var g = 0;
    for (var i = 0; i < _colorPoints * 4; i++) {
      var colorIndex = i ~/ 4;
      var value = array[i];
      switch (i % 4) {
        case 0:
          // position
          positions[colorIndex] = value;
        case 1:
          r = (value * 255).round();
        case 2:
          g = (value * 255).round();
        case 3:
          var b = (value * 255).round();
          colors[colorIndex] = Color.fromARGB(255, r, g, b);
      }
    }

    var gradientColor = GradientColor(positions, colors);
    gradientColor = _addOpacityStopsToGradientIfNeeded(gradientColor, array);
    return gradientColor;
  }

  /// This cheats a little bit.
  /// Opacity stops can be at arbitrary intervals independent of color stops.
  /// This uses the existing color stops and modifies the opacity at each existing color stop
  /// based on what the opacity would be.
  /// <p>
  /// This should be a good approximation is nearly all cases. However, if there are many more
  /// opacity stops than color stops, information will be lost.
  GradientColor _addOpacityStopsToGradientIfNeeded(
      GradientColor gradientColor, List<double> array) {
    var startIndex = _colorPoints * 4;
    if (array.length <= startIndex) {
      return gradientColor;
    }

    // When there are opacity stops, we create a merged list of color stops and opacity stops.
    // For a given color stop, we linearly interpolate the opacity for the two opacity stops around it.
    // For a given opacity stop, we linearly interpolate the color for the two color stops around it.
    var colorStopPositions = gradientColor.positions;
    var colorStopColors = gradientColor.colors;

    var opacityStops = (array.length - startIndex) ~/ 2;
    var opacityStopPositions = List<double>.filled(opacityStops, 0.0);
    var opacityStopOpacities = List<double>.filled(opacityStops, 0.0);

    for (var i = startIndex, j = 0; i < array.length; i++) {
      if (i % 2 == 0) {
        opacityStopPositions[j] = array[i];
      } else {
        opacityStopOpacities[j] = array[i];
        j++;
      }
    }

    // Pre-SKIA (Oreo) devices render artifacts when there is two stops in the same position.
    // As a result, we have to de-dupe the merge color and opacity stop positions.
    var newPositions =
        mergeUniqueElements(gradientColor.positions, opacityStopPositions);
    var newColorPoints = newPositions.length;
    var newColors = List<Color>.filled(newColorPoints, const Color(0xff000000));

    for (var i = 0; i < newColorPoints; i++) {
      var position = newPositions[i];
      var colorStopIndex = binarySearch(colorStopPositions, position);
      var opacityIndex = binarySearch(opacityStopPositions, position);
      if (colorStopIndex < 0 || opacityIndex > 0) {
        // This is a stop derived from an opacity stop.
        if (opacityIndex < 0) {
          // The formula here is derived from the return value for binarySearch. When an item isn't found, it returns -insertionPoint - 1.
          opacityIndex = -(opacityIndex + 1);
        }
        newColors[i] = _getColorInBetweenColorStops(
            position,
            opacityStopOpacities[opacityIndex],
            colorStopPositions,
            colorStopColors);
      } else {
        // This os a step derived from a color stop.
        newColors[i] = _getColorInBetweenOpacityStops(
            position,
            colorStopColors[colorStopIndex],
            opacityStopPositions,
            opacityStopOpacities);
      }
    }
    return GradientColor(newPositions, newColors);
  }

  Color _getColorInBetweenColorStops(double position, double opacity,
      List<double> colorStopPositions, List<Color> colorStopColors) {
    if (colorStopColors.length < 2 || position == colorStopPositions[0]) {
      return colorStopColors[0];
    }
    for (var i = 1; i < colorStopPositions.length; i++) {
      var colorStopPosition = colorStopPositions[i];
      if (colorStopPosition < position && i != colorStopPositions.length - 1) {
        continue;
      }
      if (i == colorStopPositions.length - 1 && position >= colorStopPosition) {
        return colorStopColors[i].withValues(alpha: opacity);
      }
      // We found the position in which position is between i - 1 and i.
      var distanceBetweenColors =
          colorStopPositions[i] - colorStopPositions[i - 1];
      var distanceToLowerColor = position - colorStopPositions[i - 1];
      var percentage = distanceToLowerColor / distanceBetweenColors;
      var upperColor = colorStopColors[i];
      var lowerColor = colorStopColors[i - 1];
      return GammaEvaluator.evaluate(percentage,
              lowerColor.withValues(alpha: 1), upperColor.withValues(alpha: 1))
          .withValues(alpha: opacity);
    }
    throw Exception('Unreachable code.');
  }

  Color _getColorInBetweenOpacityStops(double position, Color color,
      List<double> opacityStopPositions, List<double> opacityStopOpacities) {
    if (opacityStopOpacities.length < 2 ||
        position <= opacityStopPositions[0]) {
      return color.withValues(alpha: opacityStopOpacities[0]);
    }
    for (var i = 1; i < opacityStopPositions.length; i++) {
      var opacityStopPosition = opacityStopPositions[i];
      if (opacityStopPosition < position &&
          i != opacityStopPositions.length - 1) {
        continue;
      }
      final double opacity;
      if (opacityStopPosition <= position) {
        opacity = opacityStopOpacities[i];
      } else {
        // We found the position in which position in between i - 1 and i.
        var distanceBetweenOpacities =
            opacityStopPositions[i] - opacityStopPositions[i - 1];
        var distanceToLowerOpacity = position - opacityStopPositions[i - 1];
        var percentage = distanceToLowerOpacity / distanceBetweenOpacities;
        opacity = lerpDouble(
            opacityStopOpacities[i - 1], opacityStopOpacities[i], percentage)!;
      }
      return color.withValues(alpha: opacity);
    }
    throw Exception('Unreachable code.');
  }

  /// Takes two sorted float arrays and merges their elements while removing duplicates.
  static List<double> mergeUniqueElements(
      List<double> arrayA, List<double> arrayB) {
    if (arrayA.isEmpty) {
      return arrayB;
    } else if (arrayB.isEmpty) {
      return arrayA;
    }

    var aIndex = 0;
    var bIndex = 0;
    var numDuplicates = 0;
    // This will be the merged list but may be longer than what is needed if there are duplicates.
    // If there are, the 0 elements at the end need to be truncated.
    var mergedNotTruncated =
        List<double>.filled(arrayA.length + arrayB.length, 0);
    for (var i = 0; i < mergedNotTruncated.length; i++) {
      final a = aIndex < arrayA.length ? arrayA[aIndex] : double.nan;
      final b = bIndex < arrayB.length ? arrayB[bIndex] : double.nan;

      if (b.isNaN || a < b) {
        mergedNotTruncated[i] = a;
        aIndex++;
      } else if (a.isNaN || b < a) {
        mergedNotTruncated[i] = b;
        bIndex++;
      } else {
        mergedNotTruncated[i] = a;
        aIndex++;
        bIndex++;
        numDuplicates++;
      }
    }

    if (numDuplicates == 0) {
      return mergedNotTruncated;
    }

    return mergedNotTruncated
        .take(mergedNotTruncated.length - numDuplicates)
        .toList();
  }
}
