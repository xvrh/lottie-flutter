import 'package:lottie/src/model/animatable/animatable_color_value.dart';
import 'package:lottie/src/model/animatable/animatable_double_value.dart';
import 'package:lottie/src/model/content/drop_shadow_effect.dart';

import '../composition.dart';
import 'animatable_value_parser.dart';
import 'moshi/json_reader.dart';

class DropShadowEffectParser {
  static final JsonReaderOptions _dropShadowEffectNames =
      JsonReaderOptions.of(['ef']);

  static final JsonReaderOptions _innerEffectNames =
      JsonReaderOptions.of(['nm', 'v']);

  AnimatableColorValue? _color;
  AnimatableDoubleValue? _opacity;
  AnimatableDoubleValue? _direction;
  AnimatableDoubleValue? _distance;
  AnimatableDoubleValue? _radius;

  DropShadowEffect? parse(JsonReader reader, LottieComposition composition) {
    while (reader.hasNext()) {
      switch (reader.selectName(_dropShadowEffectNames)) {
        case 0:
          reader.beginArray();
          while (reader.hasNext()) {
            _maybeParseInnerEffect(reader, composition);
          }
          reader.endArray();
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }

    var color = _color;
    var opacity = _opacity;
    var direction = _direction;
    var distance = _distance;
    var radius = _radius;
    if (color != null &&
        opacity != null &&
        direction != null &&
        distance != null &&
        radius != null) {
      return DropShadowEffect(
          color: color,
          opacity: opacity,
          direction: direction,
          distance: distance,
          radius: radius);
    }
    return null;
  }

  void _maybeParseInnerEffect(
      JsonReader reader, LottieComposition composition) {
    var currentEffectName = '';
    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_innerEffectNames)) {
        case 0:
          currentEffectName = reader.nextString();
          break;
        case 1:
          switch (currentEffectName) {
            case 'Shadow Color':
              _color = AnimatableValueParser.parseColor(reader, composition);
              break;
            case 'Opacity':
              _opacity = AnimatableValueParser.parseFloat(reader, composition,
                  isDp: false);
              break;
            case 'Direction':
              _direction = AnimatableValueParser.parseFloat(reader, composition,
                  isDp: false);
              break;
            case 'Distance':
              _distance = AnimatableValueParser.parseFloat(reader, composition);
              break;
            case 'Softness':
              _radius = AnimatableValueParser.parseFloat(reader, composition);
              break;
            default:
              reader.skipValue();
              break;
          }
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();
  }
}
