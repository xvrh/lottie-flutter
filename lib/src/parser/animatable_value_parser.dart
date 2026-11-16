import '../composition.dart';
import '../model/animatable/animatable_color_value.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_gradient_color_value.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/animatable/animatable_point_value.dart';
import '../model/animatable/animatable_scale_value.dart';
import '../model/animatable/animatable_shape_value.dart';
import '../model/animatable/animatable_text_frame.dart';
import 'color_parser.dart';
import 'document_data_parser.dart';
import 'float_parser.dart';
import 'gradient_color_parser.dart';
import 'integer_parser.dart';
import 'keyframes_parser.dart';
import 'moshi/json_reader.dart';
import 'offset_parser.dart';
import 'scale_xy_parser.dart';
import 'shape_data_parser.dart';
import 'value_parser.dart';

class AnimatableValueParser {
  AnimatableValueParser._();

  static AnimatableDoubleValue parseFloat(
    JsonReader reader,
    LottieComposition composition,
  ) {
    var (:keyframes, :loop) = parse(reader, composition, floatParser);
    return AnimatableDoubleValue.fromKeyframes(keyframes, loop: loop);
  }

  static AnimatableIntegerValue parseInteger(
    JsonReader reader,
    LottieComposition composition,
  ) {
    var (:keyframes, :loop) = parse(reader, composition, integerParser);
    return AnimatableIntegerValue.fromKeyframes(keyframes, loop: loop);
  }

  static AnimatablePointValue parsePoint(
    JsonReader reader,
    LottieComposition composition,
  ) {
    var (:keyframes, :loop) = KeyframesParser.parse(
      reader,
      composition,
      offsetParser,
      multiDimensional: true,
    );
    return AnimatablePointValue.fromKeyframes(keyframes, loop: loop);
  }

  static AnimatableScaleValue parseScale(
    JsonReader reader,
    LottieComposition composition,
  ) {
    var (:keyframes, :loop) = parse(reader, composition, scaleXYParser);
    return AnimatableScaleValue.fromKeyframes(keyframes, loop: loop);
  }

  static AnimatableShapeValue parseShapeData(
    JsonReader reader,
    LottieComposition composition,
  ) {
    var (:keyframes, :loop) = parse(reader, composition, shapeDataParser);
    return AnimatableShapeValue.fromKeyframes(keyframes, loop: loop);
  }

  static AnimatableTextFrame parseDocumentData(
    JsonReader reader,
    LottieComposition composition,
  ) {
    var (:keyframes, :loop) = parse(reader, composition, documentDataParser);
    return AnimatableTextFrame.fromKeyframes(keyframes, loop: loop);
  }

  static AnimatableColorValue parseColor(
    JsonReader reader,
    LottieComposition composition,
  ) {
    var (:keyframes, :loop) = parse(reader, composition, colorParser);
    return AnimatableColorValue.fromKeyframes(keyframes, loop: loop);
  }

  static AnimatableGradientColorValue parseGradientColor(
    JsonReader reader,
    LottieComposition composition,
    int points,
  ) {
    var (:keyframes, :loop) = parse(
      reader,
      composition,
      GradientColorParser(points).parse,
    );
    return AnimatableGradientColorValue.fromKeyframes(keyframes, loop: loop);
  }

  static ParsedKeyframes<T> parse<T>(
    JsonReader reader,
    LottieComposition composition,
    ValueParser<T> valueParser,
  ) {
    return KeyframesParser.parse(reader, composition, valueParser);
  }
}
