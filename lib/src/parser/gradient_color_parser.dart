import 'dart:ui';
import '../model/content/gradient_color.dart';
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
  GradientColor parse(JsonReader reader, {required double scale}) {
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
          break;
        case 1:
          r = (value * 255).round();
          break;
        case 2:
          g = (value * 255).round();
          break;
        case 3:
          var b = (value * 255).round();
          colors[colorIndex] = Color.fromARGB(255, r, g, b);
          break;
      }
    }

    var gradientColor = GradientColor(positions, colors);
    _addOpacityStopsToGradientIfNeeded(gradientColor, array);
    return gradientColor;
  }

  /// This cheats a little bit.
  /// Opacity stops can be at arbitrary intervals independent of color stops.
  /// This uses the existing color stops and modifies the opacity at each existing color stop
  /// based on what the opacity would be.
  /// <p>
  /// This should be a good approximation is nearly all cases. However, if there are many more
  /// opacity stops than color stops, information will be lost.
  void _addOpacityStopsToGradientIfNeeded(
      GradientColor gradientColor, List<double> array) {
    var startIndex = _colorPoints * 4;
    if (array.length <= startIndex) {
      return;
    }

    var opacityStops = (array.length - startIndex) ~/ 2;
    var positions = List<double>.filled(opacityStops, 0.0);
    var opacities = List<double>.filled(opacityStops, 0.0);

    for (var i = startIndex, j = 0; i < array.length; i++) {
      if (i % 2 == 0) {
        positions[j] = array[i];
      } else {
        opacities[j] = array[i];
        j++;
      }
    }

    for (var i = 0; i < gradientColor.size; i++) {
      var color = gradientColor.colors[i];
      color = color.withAlpha(_getOpacityAtPosition(
          gradientColor.positions[i], positions, opacities));
      gradientColor.colors[i] = color;
    }
  }

  int _getOpacityAtPosition(
      double position, List<double> positions, List<double> opacities) {
    for (var i = 1; i < positions.length; i++) {
      var lastPosition = positions[i - 1];
      var thisPosition = positions[i];
      if (positions[i] >= position) {
        var progress =
            (position - lastPosition) / (thisPosition - lastPosition);
        progress = progress.clamp(0, 1);
        if (progress.isNaN) {
          progress = 0.0;
        }
        return (255 * lerpDouble(opacities[i - 1], opacities[i], progress)!)
            .round();
      }
    }
    return (255 * opacities[opacities.length - 1]).round();
  }
}
