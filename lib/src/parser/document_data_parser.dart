import 'dart:ui';
import '../model/document_data.dart';
import 'json_utils.dart';
import 'moshi/json_reader.dart';

final JsonReaderOptions _names = JsonReaderOptions.of(
    ['t', 'f', 's', 'j', 'tr', 'lh', 'ls', 'fc', 'sc', 'sw', 'of']);

DocumentData documentDataParser(JsonReader reader, {required double scale}) {
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

  reader.beginObject();
  while (reader.hasNext()) {
    switch (reader.selectName(_names)) {
      case 0:
        text = reader.nextString();
        break;
      case 1:
        fontName = reader.nextString();
        break;
      case 2:
        size = reader.nextDouble();
        break;
      case 3:
        var justificationInt = reader.nextInt();
        if (justificationInt > Justification.center.index ||
            justificationInt < 0) {
          justification = Justification.center;
        } else {
          justification = Justification.values[justificationInt];
        }
        break;
      case 4:
        tracking = reader.nextInt();
        break;
      case 5:
        lineHeight = reader.nextDouble();
        break;
      case 6:
        baselineShift = reader.nextDouble();
        break;
      case 7:
        fillColor = JsonUtils.jsonToColor(reader);
        break;
      case 8:
        strokeColor = JsonUtils.jsonToColor(reader);
        break;
      case 9:
        strokeWidth = reader.nextDouble();
        break;
      case 10:
        strokeOverFill = reader.nextBoolean();
        break;
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
      strokeOverFill: strokeOverFill);
}
