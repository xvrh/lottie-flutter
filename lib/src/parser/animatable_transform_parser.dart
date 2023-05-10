import 'dart:ui';
import '../composition.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_integer_value.dart';
import '../model/animatable/animatable_path_value.dart';
import '../model/animatable/animatable_scale_value.dart';
import '../model/animatable/animatable_split_dimension_path_value.dart';
import '../model/animatable/animatable_transform.dart';
import '../model/animatable/animatable_value.dart';
import '../value/keyframe.dart';
import 'animatable_path_value_parser.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class AnimatableTransformParser {
  AnimatableTransformParser._();

  static final JsonReaderOptions _names = JsonReaderOptions.of(
      ['a', 'p', 's', 'rz', 'r', 'o', 'so', 'eo', 'sk', 'sa']);
  static final JsonReaderOptions _animatableNames = JsonReaderOptions.of(['k']);

  static AnimatableTransform parse(
      JsonReader reader, LottieComposition composition) {
    AnimatablePathValue? anchorPoint;
    AnimatableValue<Offset, Offset>? position;
    AnimatableScaleValue? scale;
    AnimatableDoubleValue? rotation;
    AnimatableIntegerValue? opacity;
    AnimatableDoubleValue? startOpacity;
    AnimatableDoubleValue? endOpacity;
    AnimatableDoubleValue? skew;
    AnimatableDoubleValue? skewAngle;

    var isObject = reader.peek() == Token.beginObject;
    if (isObject) {
      reader.beginObject();
    }
    while (reader.hasNext()) {
      var name = reader.selectName(_names);
      switch (name) {
        case 0:
          reader.beginObject();
          while (reader.hasNext()) {
            switch (reader.selectName(_animatableNames)) {
              case 0:
                anchorPoint =
                    AnimatablePathValueParser.parse(reader, composition);
              default:
                reader.skipName();
                reader.skipValue();
            }
          }
          reader.endObject();
        case 1:
          position =
              AnimatablePathValueParser.parseSplitPath(reader, composition);
        case 2:
          scale = AnimatableValueParser.parseScale(reader, composition);
        case 3:
        case 4:
          if (name == 3) {
            composition.addWarning("Lottie doesn't support 3D layers.");
          }

          // Sometimes split path rotation gets exported like:
          //         "rz": {
          //           "a": 1,
          //           "k": [
          //             {}
          //           ]
          //         },
          // which doesn't parse to a real keyframe.
          rotation = AnimatableValueParser.parseFloat(reader, composition);
          if (rotation.keyframes.isEmpty) {
            rotation.keyframes.add(Keyframe(composition,
                startValue: 0.0,
                endValue: 0.0,
                startFrame: 0.0,
                endFrame: composition.endFrame));
          } else if (rotation.keyframes.first.startValue == null) {
            rotation.keyframes.first = Keyframe(composition,
                startValue: 0.0,
                endValue: 0.0,
                startFrame: 0.0,
                endFrame: composition.endFrame);
          }
        case 5:
          opacity = AnimatableValueParser.parseInteger(reader, composition);
        case 6:
          startOpacity = AnimatableValueParser.parseFloat(reader, composition);
        case 7:
          endOpacity = AnimatableValueParser.parseFloat(reader, composition);
        case 8:
          skew = AnimatableValueParser.parseFloat(reader, composition);
        case 9:
          skewAngle = AnimatableValueParser.parseFloat(reader, composition);
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    if (isObject) {
      reader.endObject();
    }

    if (isAnchorPointIdentity(anchorPoint)) {
      anchorPoint = null;
    }
    if (isPositionIdentity(position)) {
      position = null;
    }
    if (isRotationIdentity(rotation)) {
      rotation = null;
    }
    if (isScaleIdentity(scale)) {
      scale = null;
    }
    if (isSkewIdentity(skew)) {
      skew = null;
    }
    if (isSkewAngleIdentity(skewAngle)) {
      skewAngle = null;
    }
    return AnimatableTransform(
        anchorPoint: anchorPoint,
        position: position,
        scale: scale,
        rotation: rotation,
        opacity: opacity,
        startOpacity: startOpacity,
        endOpacity: endOpacity,
        skew: skew,
        skewAngle: skewAngle);
  }

  static bool isAnchorPointIdentity(AnimatablePathValue? anchorPoint) {
    return anchorPoint == null ||
        (anchorPoint.isStatic &&
            anchorPoint.keyframes.first.startValue == Offset.zero);
  }

  static bool isPositionIdentity(AnimatableValue<Offset, Offset>? position) {
    return position == null ||
        (position is! AnimatableSplitDimensionPathValue &&
            position.isStatic &&
            position.keyframes.first.startValue == Offset.zero);
  }

  static bool isRotationIdentity(AnimatableDoubleValue? rotation) {
    return rotation == null ||
        (rotation.isStatic && rotation.keyframes.first.startValue == 0.0);
  }

  static bool isScaleIdentity(AnimatableScaleValue? scale) {
    return scale == null ||
        (scale.isStatic &&
            scale.keyframes.first.startValue == const Offset(1.0, 1.0));
  }

  static bool isSkewIdentity(AnimatableDoubleValue? skew) {
    return skew == null ||
        (skew.isStatic && skew.keyframes.first.startValue == 0.0);
  }

  static bool isSkewAngleIdentity(AnimatableDoubleValue? skewAngle) {
    return skewAngle == null ||
        (skewAngle.isStatic && skewAngle.keyframes.first.startValue == 0.0);
  }
}
