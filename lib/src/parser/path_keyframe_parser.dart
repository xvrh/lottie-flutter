import 'dart:ui';
import '../animation/keyframe/path_keyframe.dart';
import '../composition.dart';
import 'keyframe_parser.dart';
import 'moshi/json_reader.dart';
import 'path_parser.dart';

class PathKeyframeParser {
  PathKeyframeParser._();

  static PathKeyframe parse(JsonReader reader, LottieComposition composition) {
    var animated = reader.peek() == Token.beginObject;
    var keyframe = KeyframeParser.parse<Offset>(reader, composition, pathParser,
        animated: animated);

    return PathKeyframe(composition, keyframe);
  }
}
