import '../composition.dart';
import '../model/animatable/animatable_color_value.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/animatable/animatable_text_properties.dart';
import '../model/animatable/animatable_text_range_selector.dart';
import '../model/animatable/animatable_text_style.dart';
import '../model/content/text_range_units.dart';
import '../value/keyframe.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class AnimatableTextPropertiesParser {
  static final JsonReaderOptions _propertiesNames = JsonReaderOptions.of([
    's', // Range selector
    'a', // Text style for this range
  ]);
  static final JsonReaderOptions _animatableRangePropertiesNames =
      JsonReaderOptions.of([
        's', // start
        'e', // end
        'o', // offset
        'r', // text range units (percent or index)
      ]);
  static final JsonReaderOptions _animatablePropertiesNames =
      JsonReaderOptions.of([
        'fc',
        'sc',
        'sw',
        't',
        'o', // opacity
      ]);

  AnimatableTextPropertiesParser();

  static AnimatableTextProperties parse(
    JsonReader reader,
    LottieComposition composition,
  ) {
    AnimatableTextStyle? textStyle;
    AnimatableTextRangeSelector? rangeSelector;

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_propertiesNames)) {
        case 0: // Range selector
          rangeSelector = _parseAnimatableTextRangeSelector(
            reader,
            composition,
          );
        case 1: // Text style for this range
          textStyle = _parseAnimatableTextStyle(reader, composition);
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    return AnimatableTextProperties(
      textStyle: textStyle,
      rangeSelector: rangeSelector,
    );
  }

  static AnimatableTextRangeSelector _parseAnimatableTextRangeSelector(
    JsonReader reader,
    LottieComposition composition,
  ) {
    AnimatableIntegerValue? start;
    AnimatableIntegerValue? end;
    AnimatableIntegerValue? offset;
    var units = TextRangeUnits.charIndex;

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_animatableRangePropertiesNames)) {
        case 0: // start
          start = AnimatableValueParser.parseInteger(reader, composition);
        case 1: // end
          end = AnimatableValueParser.parseInteger(reader, composition);
        case 2: // offset
          offset = AnimatableValueParser.parseInteger(reader, composition);
        case 3: // text range units (percent or index)
          var textRangeUnits = reader.nextInt();
          if (textRangeUnits != 1 && textRangeUnits != 2) {
            composition.addWarning(
              'Unsupported text range units: $textRangeUnits',
            );
            units = TextRangeUnits.charIndex;
          } else {
            units = textRangeUnits == 1
                ? TextRangeUnits.percent
                : TextRangeUnits.charIndex;
          }
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    // If no start value is provided, default to a non-animated value of 0 to match
    // After Effects/Bodymovin.
    if (start == null && end != null) {
      start = AnimatableIntegerValue.fromKeyframes([Keyframe.nonAnimated(0)]);
    }

    return AnimatableTextRangeSelector(
      start: start,
      end: end,
      offset: offset,
      units: units,
    );
  }

  static AnimatableTextStyle _parseAnimatableTextStyle(
    JsonReader reader,
    LottieComposition composition,
  ) {
    AnimatableColorValue? color;
    AnimatableColorValue? stroke;
    AnimatableDoubleValue? strokeWidth;
    AnimatableDoubleValue? tracking;
    AnimatableIntegerValue? opacity;

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_animatablePropertiesNames)) {
        case 0:
          color = AnimatableValueParser.parseColor(reader, composition);
        case 1:
          stroke = AnimatableValueParser.parseColor(reader, composition);
        case 2:
          strokeWidth = AnimatableValueParser.parseFloat(reader, composition);
        case 3:
          tracking = AnimatableValueParser.parseFloat(reader, composition);
        case 4: // opacity
          opacity = AnimatableValueParser.parseInteger(reader, composition);
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    return AnimatableTextStyle(
      color: color,
      stroke: stroke,
      strokeWidth: strokeWidth,
      tracking: tracking,
      opacity: opacity,
    );
  }
}
