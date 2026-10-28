import 'dart:ui';

import '../composition.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_path_value.dart';
import '../model/animatable/animatable_split_dimension_path_value.dart';
import '../model/animatable/animatable_value.dart';
import '../value/keyframe.dart';
import 'animatable_value_parser.dart';
import 'json_utils.dart';
import 'keyframes_parser.dart';
import 'moshi/json_reader.dart';
import 'path_keyframe_parser.dart';

class AnimatablePathValueParser {
  static final _names = JsonReaderOptions.of(['k', 'x', 'y', 'sid']);
  static final _propertyNames = JsonReaderOptions.of(['k', 'sid']);

  AnimatablePathValueParser._();

  static AnimatablePathValue parse(
    JsonReader reader,
    LottieComposition composition,
  ) {
    var keyframes = <Keyframe<Offset>>[];
    if (reader.peek() == Token.beginArray) {
      reader.beginArray();
      while (reader.hasNext()) {
        keyframes.add(PathKeyframeParser.parse(reader, composition));
      }
      reader.endArray();
      KeyframesParser.setEndFrames(keyframes);
    } else {
      keyframes.add(
        Keyframe<Offset>.nonAnimated(JsonUtils.jsonToPoint(reader)),
      );
    }
    return AnimatablePathValue.fromKeyframes(keyframes);
  }

  /// Parses a property whose value ("k") is a path value, or the value of its
  /// slot.
  static AnimatablePathValue? parseProperty(
    JsonReader reader,
    LottieComposition composition,
  ) {
    AnimatablePathValue? value;
    String? slotId;
    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_propertyNames)) {
        case 0:
          value = parse(reader, composition);
        case 1:
          slotId = reader.nextString();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    var slot = KeyframesParser.slotReader(composition, slotId);
    if (slot != null) {
      return parseProperty(slot, composition);
    }
    return value;
  }

  /// Returns either an {@link AnimatablePathValue} or an {@link AnimatableSplitDimensionPathValue}.
  static AnimatableValue<Offset, Offset> parseSplitPath(
    JsonReader reader,
    LottieComposition composition,
  ) {
    AnimatablePathValue? pathAnimation;
    AnimatableDoubleValue? xAnimation;
    AnimatableDoubleValue? yAnimation;

    var hasExpressions = false;
    String? slotId;

    reader.beginObject();
    while (reader.peek() != Token.endObject) {
      switch (reader.selectName(_names)) {
        case 0:
          pathAnimation = AnimatablePathValueParser.parse(reader, composition);
        case 1:
          if (reader.peek() == Token.string) {
            hasExpressions = true;
            reader.skipValue();
          } else {
            xAnimation = AnimatableValueParser.parseFloat(reader, composition);
          }
        case 2:
          if (reader.peek() == Token.string) {
            hasExpressions = true;
            reader.skipValue();
          } else {
            yAnimation = AnimatableValueParser.parseFloat(reader, composition);
          }
        case 3:
          slotId = reader.nextString();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    var slot = KeyframesParser.slotReader(composition, slotId);
    if (slot != null) {
      return parseSplitPath(slot, composition);
    }

    if (hasExpressions) {
      composition.addWarning("Lottie doesn't support expressions.");
    }

    if (pathAnimation != null) {
      return pathAnimation;
    }
    return AnimatableSplitDimensionPathValue(xAnimation!, yAnimation!);
  }
}
