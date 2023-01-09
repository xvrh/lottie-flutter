import '../composition.dart';
import '../model/animatable/animatable_color_value.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_gradient_color_value.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/animatable/animatable_point_value.dart';
import '../model/animatable/animatable_scale_value.dart';
import '../model/animatable/animatable_shape_value.dart';
import '../model/animatable/animatable_text_frame.dart';
import '../value/keyframe.dart';
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
      JsonReader reader, LottieComposition composition) {
    return AnimatableDoubleValue.fromKeyframes(
        parse(reader, composition, floatParser));
  }

  static AnimatableIntegerValue parseInteger(
      JsonReader reader, LottieComposition composition) {
    return AnimatableIntegerValue.fromKeyframes(
        parse(reader, composition, integerParser));
  }

  static AnimatablePointValue parsePoint(
      JsonReader reader, LottieComposition composition) {
    return AnimatablePointValue.fromKeyframes(KeyframesParser.parse(
        reader, composition, offsetParser,
        multiDimensional: true));
  }

  static AnimatableScaleValue parseScale(
      JsonReader reader, LottieComposition composition) {
    return AnimatableScaleValue.fromKeyframes(
        parse(reader, composition, scaleXYParser));
  }

  static AnimatableShapeValue parseShapeData(
      JsonReader reader, LottieComposition composition) {
    return AnimatableShapeValue.fromKeyframes(
        parse(reader, composition, shapeDataParser));
  }

  static AnimatableTextFrame parseDocumentData(
      JsonReader reader, LottieComposition composition) {
    return AnimatableTextFrame.fromKeyframes(
        parse(reader, composition, documentDataParser));
  }

  static AnimatableColorValue parseColor(
      JsonReader reader, LottieComposition composition) {
    return AnimatableColorValue.fromKeyframes(
        parse(reader, composition, colorParser));
  }

  static AnimatableGradientColorValue parseGradientColor(
      JsonReader reader, LottieComposition composition, int points) {
    return AnimatableGradientColorValue.fromKeyframes(
        parse(reader, composition, GradientColorParser(points).parse));
  }

  static List<Keyframe<T>> parse<T>(JsonReader reader,
      LottieComposition composition, ValueParser<T> valueParser) {
    return KeyframesParser.parse(reader, composition, valueParser);
  }
}
