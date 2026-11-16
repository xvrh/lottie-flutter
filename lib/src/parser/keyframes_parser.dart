import '../composition.dart';
import '../model/keyframe_loop.dart';
import '../value/keyframe.dart';
import 'keyframe_parser.dart';
import 'moshi/json_reader.dart';
import 'value_parser.dart';

/// The keyframes of a property, and their repetition by a `loopOut` or
/// `loopIn` expression.
typedef ParsedKeyframes<T> = ({
  List<Keyframe<T>> keyframes,
  KeyframeLoop? loop,
});

class KeyframesParser {
  static final JsonReaderOptions _names = JsonReaderOptions.of([
    'k',
    'sid',
    'x',
  ]);

  KeyframesParser._();

  static ParsedKeyframes<T> parse<T>(
    JsonReader reader,
    LottieComposition composition,
    ValueParser<T> valueParser, {
    bool multiDimensional = false,
  }) {
    var keyframes = <Keyframe<T>>[];
    String? slotId;
    String? expression;

    if (reader.peek() == Token.string) {
      composition.addWarning("Lottie doesn't support expressions.");
      return (keyframes: keyframes, loop: null);
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
        case 2:
          if (reader.peek() == Token.string) {
            expression = reader.nextString();
          } else {
            reader.skipValue();
          }
        default:
          reader.skipValue();
      }
    }
    reader.endObject();

    var slot = slotReader(composition, slotId);
    if (slot != null) {
      return parse(
        slot,
        composition,
        valueParser,
        multiDimensional: multiDimensional,
      );
    }

    setEndFrames(keyframes);
    var loop = expression == null
        ? null
        : parseExpression(composition, expression, keyframes);
    return (keyframes: keyframes, loop: loop);
  }

  /// The loop of [expression], the expression of the property with
  /// [keyframes]. Warns that the expression is ignored if it is not a loop.
  static KeyframeLoop? parseExpression(
    LottieComposition composition,
    String expression,
    List<Keyframe<Object?>> keyframes,
  ) {
    var (:isLoop, :loop) = KeyframeLoop.parse(expression, keyframes);
    if (!isLoop) {
      composition.addWarning("Lottie doesn't support expressions.");
    }
    return loop;
  }

  /// As in lottie-web, a property with the id of a slot (`sid`) takes the
  /// value of that slot, whatever its type, static or animated. Returns the
  /// property of the slot with [slotId], to parse instead, if the file has it.
  static JsonReader? slotReader(LottieComposition composition, String? slotId) {
    if (slotId == null) {
      return null;
    }
    var parameters = CompositionParameters.forComposition(composition);
    var slot = parameters.slots[slotId];
    if (slot == null) {
      parameters.hasUnresolvedSlotIds = true;
      return null;
    }
    return JsonReader.fromBytes(slot);
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
