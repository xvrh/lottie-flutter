import 'dart:ui';
import '../model/content/shape_data.dart';
import '../model/cubic_curve_data.dart';
import 'json_utils.dart';
import 'moshi/json_reader.dart';

final JsonReaderOptions _names = JsonReaderOptions.of(['c', 'v', 'i', 'o']);

ShapeData shapeDataParser(JsonReader reader) {
  // Sometimes the points data is in a array of length 1. Sometimes the data is at the top
  // level.
  if (reader.peek() == Token.beginArray) {
    reader.beginArray();
  }

  var closed = false;
  List<Offset>? pointsArray;
  List<Offset>? inTangents;
  List<Offset>? outTangents;
  reader.beginObject();

  while (reader.hasNext()) {
    switch (reader.selectName(_names)) {
      case 0:
        closed = reader.nextBoolean();
      case 1:
        pointsArray = JsonUtils.jsonToPoints(reader);
      case 2:
        inTangents = JsonUtils.jsonToPoints(reader);
      case 3:
        outTangents = JsonUtils.jsonToPoints(reader);
      default:
        reader.skipName();
        reader.skipValue();
    }
  }

  reader.endObject();

  if (reader.peek() == Token.endArray) {
    reader.endArray();
  }

  if (pointsArray == null || inTangents == null || outTangents == null) {
    throw Exception('Shape data was missing information.');
  }

  if (pointsArray.isEmpty) {
    return ShapeData(<CubicCurveData>[],
        initialPoint: Offset.zero, closed: false);
  }

  var length = pointsArray.length;
  var vertex = pointsArray[0];
  var initialPoint = vertex;
  var curves = <CubicCurveData>[];

  for (var i = 1; i < length; i++) {
    vertex = pointsArray[i];
    var previousVertex = pointsArray[i - 1];
    var cp1 = outTangents[i - 1];
    var cp2 = inTangents[i];
    var shapeCp1 = previousVertex + cp1;
    var shapeCp2 = vertex + cp2;
    curves.add(CubicCurveData()
      ..controlPoint1 = shapeCp1
      ..controlPoint2 = shapeCp2
      ..vertex = vertex);
  }

  if (closed) {
    vertex = pointsArray[0];
    var previousVertex = pointsArray[length - 1];
    var cp1 = outTangents[length - 1];
    var cp2 = inTangents[0];

    var shapeCp1 = previousVertex + cp1;
    var shapeCp2 = vertex + cp2;

    curves.add(CubicCurveData()
      ..controlPoint1 = shapeCp1
      ..controlPoint2 = shapeCp2
      ..vertex = vertex);
  }
  return ShapeData(curves, initialPoint: initialPoint, closed: closed);
}
