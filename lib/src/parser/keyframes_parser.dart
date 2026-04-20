import '../composition.dart';
import '../value/keyframe.dart';
import 'keyframe_parser.dart';
import 'moshi/json_reader.dart';
import 'value_parser.dart';

class KeyframesParser {
  static final JsonReaderOptions _names = JsonReaderOptions.of(['k', 'sid']);

  KeyframesParser._();

  static List<Keyframe<T>> parse<T>(
    JsonReader reader,
    LottieComposition composition,
    ValueParser<T> valueParser, {
    bool multiDimensional = false,
  }) {
    return parseWithSlot(
      reader,
      composition,
      valueParser,
      multiDimensional: multiDimensional,
    ).keyframes;
  }

  static ({List<Keyframe<T>> keyframes, String? slotId}) parseWithSlot<T>(
    JsonReader reader,
    LottieComposition composition,
    ValueParser<T> valueParser, {
    bool multiDimensional = false,
  }) {
    var keyframes = <Keyframe<T>>[];
    String? slotId;

    if (reader.peek() == Token.string) {
      composition.addWarning("Lottie doesn't support expressions.");
      return (keyframes: keyframes, slotId: null);
    }

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          if (reader.peek() == Token.beginArray) {
            reader.beginArray();

            if (reader.peek() == Token.number) {
              // For properties in which the static value is an array of numbers.
              keyframes.add(
                KeyframeParser.parse(
                  reader,
                  composition,
                  valueParser,
                  animated: false,
                  multiDimensional: multiDimensional,
                ),
              );
            } else {
              while (reader.hasNext()) {
                keyframes.add(
                  KeyframeParser.parse(
                    reader,
                    composition,
                    valueParser,
                    animated: true,
                    multiDimensional: multiDimensional,
                  ),
                );
              }
            }
            reader.endArray();
          } else {
            keyframes.add(
              KeyframeParser.parse(
                reader,
                composition,
                valueParser,
                animated: false,
                multiDimensional: multiDimensional,
              ),
            );
          }
        case 1:
          slotId = reader.nextString();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    setEndFrames(keyframes);
    return (keyframes: keyframes, slotId: slotId);
  }

  /// The json doesn't include end frames. The data can be taken from the start frame of the next
  /// keyframe though.
  static void setEndFrames<T>(List<Keyframe<T>> keyframes) {
    var size = keyframes.length;
    for (var i = 0; i < size - 1; i++) {
      // In the json, the keyframes only contain their starting frame.
      var keyframe = keyframes[i];
      var nextKeyframe = keyframes[i + 1];
      keyframe.endFrame = nextKeyframe.startFrame;
      if (keyframe.endValue == null && nextKeyframe.startValue != null) {
        keyframe.endValue = nextKeyframe.startValue;
      }
    }
    var lastKeyframe = keyframes[size - 1];
    if (lastKeyframe.startValue == null || lastKeyframe.endValue == null) {
      if (keyframes.length == 1) {
        lastKeyframe.endValue ??= lastKeyframe.startValue;
      } else if (lastKeyframe.startValue != null &&
          keyframes[size - 2].endValue != lastKeyframe.startValue) {
        // The previous keyframe is a hold that ends on its own value: the last
        // keyframe gives the value from its frame on.
        lastKeyframe.endValue = lastKeyframe.startValue;
      } else {
        // The only purpose the last keyframe has is to provide the end frame of the previous
        // keyframe.
        keyframes.remove(lastKeyframe);
      }
    }
  }
}
