import 'dart:ui';
import '../model/document_data.dart';
import 'json_utils.dart';
import 'moshi/json_reader.dart';

final JsonReaderOptions _names = JsonReaderOptions.of([
  't', // 0
  'f', // 1
  's', // 2
  'j', // 3
  'tr', // 4
  'lh', // 5
  'ls', // 6
  'fc', // 7
  'sc', // 8
  'sw', // 9
  'of', // 10
  'ps', // 11
  'sz', // 12
]);

DocumentData documentDataParser(JsonReader reader) {
  String? text;
  String? fontName;
  var size = 0.0;
  var justification = Justification.center;
  var tracking = 0;
  var lineHeight = 0.0;
  var baselineShift = 0.0;
  var fillColor = const Color(0x00000000);
  var strokeColor = const Color(0x00000000);
  var strokeWidth = 0.0;
  var strokeOverFill = true;
  Offset? boxPosition;
  Offset? boxSize;

  reader.beginObject();
  while (reader.hasNext()) {
    switch (reader.selectName(_names)) {
      case 0:
        text = reader.nextString();
      case 1:
        fontName = reader.nextString();
      case 2:
        size = reader.nextDouble();
      case 3:
        var justificationInt = reader.nextInt();
        if (justificationInt > Justification.center.index ||
            justificationInt < 0) {
          justification = Justification.center;
        } else {
          justification = Justification.values[justificationInt];
        }
      case 4:
        tracking = reader.nextInt();
      case 5:
        lineHeight = reader.nextDouble();
      case 6:
        baselineShift = reader.nextDouble();
      case 7:
        fillColor = JsonUtils.jsonToColor(reader);
      case 8:
        strokeColor = JsonUtils.jsonToColor(reader);
      case 9:
        strokeWidth = reader.nextDouble();
      case 10:
        strokeOverFill = reader.nextBoolean();
      case 11:
        reader.beginArray();
        boxPosition = Offset(reader.nextDouble(), reader.nextDouble());
        reader.endArray();
      case 12:
        reader.beginArray();
        boxSize = Offset(reader.nextDouble(), reader.nextDouble());
        reader.endArray();
      default:
        reader.skipName();
        reader.skipValue();
    }
  }
  reader.endObject();

  return DocumentData(
    text: text ?? '',
    fontName: fontName,
    size: size,
    justification: justification,
    tracking: tracking,
    lineHeight: lineHeight,
    baselineShift: baselineShift,
    color: fillColor,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    strokeOverFill: strokeOverFill,
    boxPosition: boxPosition,
    boxSize: boxSize,
  );
}
