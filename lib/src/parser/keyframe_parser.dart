import 'dart:math';
import 'package:flutter/widgets.dart';
import '../composition.dart';
import '../utils/path_interpolator.dart';
import '../utils/utils.dart';
import '../value/keyframe.dart';
import 'json_utils.dart';
import 'moshi/json_reader.dart';
import 'value_parser.dart';

class KeyframeParser {
  /// Some animations get exported with insane cp values in the tens of thousands.
  /// PathInterpolator fails to create the interpolator in those cases and hangs.
  /// Clamping the cp helps prevent that.
  static final double _maxCpValue = 100;
  static final Curve _linearInterpolator = Curves.linear;
  static final Map<int, Curve> _pathInterpolatorCache = <int, Curve>{};

  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['t', 's', 'e', 'o', 'i', 'h', 'to', 'ti']);

  static Keyframe<T> parse<T>(JsonReader reader, LottieComposition composition,
      double scale, ValueParser<T> valueParser, bool animated) {
    if (animated) {
      return _parseKeyframe(composition, reader, scale, valueParser);
    } else {
      return _parseStaticValue(reader, scale, valueParser);
    }
  }

  /// beginObject will already be called on the keyframe so it can be differentiated with
  /// a non animated value.
  static Keyframe<T> _parseKeyframe<T>(LottieComposition composition,
      JsonReader reader, double scale, ValueParser<T> valueParser) {
    Offset? cp1;
    Offset? cp2;
    var startFrame = 0.0;
    T? startValue;
    T? endValue;
    var hold = false;
    Curve interpolator;

    // Only used by PathKeyframe
    Offset? pathCp1;
    Offset? pathCp2;

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          startFrame = reader.nextDouble();
          break;
        case 1:
          startValue = valueParser(reader, scale: scale);
          break;
        case 2:
          endValue = valueParser(reader, scale: scale);
          break;
        case 3:
          cp1 = JsonUtils.jsonToPoint(reader, scale);
          break;
        case 4:
          cp2 = JsonUtils.jsonToPoint(reader, scale);
          break;
        case 5:
          hold = reader.nextInt() == 1;
          break;
        case 6:
          pathCp1 = JsonUtils.jsonToPoint(reader, scale);
          break;
        case 7:
          pathCp2 = JsonUtils.jsonToPoint(reader, scale);
          break;
        default:
          reader.skipValue();
      }
    }
    reader.endObject();

    if (hold) {
      endValue = startValue;
      // TODO: create a HoldInterpolator so progress changes don't invalidate.
      interpolator = _linearInterpolator;
    } else if (cp1 != null && cp2 != null) {
      cp1 = Offset(cp1.dx.clamp(-scale, scale).toDouble(),
          cp1.dy.clamp(-_maxCpValue, _maxCpValue).toDouble());
      cp2 = Offset(cp2.dx.clamp(-scale, scale).toDouble(),
          cp2.dy.clamp(-_maxCpValue, _maxCpValue).toDouble());
      var hash = Utils.hashFor(cp1.dx, cp1.dy, cp2.dx, cp2.dy);

      interpolator = _pathInterpolatorCache.putIfAbsent(hash, () {
        cp1 = cp1! / scale;
        cp2 = cp2! / scale;

        try {
          return PathInterpolator.cubic(cp1!.dx, cp1!.dy, cp2!.dx, cp2!.dy);
        } catch (e) {
          print('DEBUG: Path interpolator error $e');
          //TODO(xha): check the error message for Flutter
          if ('$e'.contains('The Path cannot loop back on itself.')) {
            // If a control point extends beyond the previous/next point then it will cause the value of the interpolator to no
            // longer monotonously increase. This clips the control point bounds to prevent that from happening.
            // NOTE: this will make the rendered animation behave slightly differently than the original.
            return PathInterpolator.cubic(
                min(cp1!.dx, 1.0), cp1!.dy, max(cp2!.dx, 0.0), cp2!.dy);
          } else {
            // We failed to create the interpolator. Fall back to linear.
            return Curves.linear;
          }
        }
      });
    } else {
      interpolator = _linearInterpolator;
    }

    var keyframe = Keyframe<T>(composition,
        startValue: startValue,
        endValue: endValue,
        interpolator: interpolator,
        startFrame: startFrame,
        endFrame: null);
    keyframe.pathCp1 = pathCp1;
    keyframe.pathCp2 = pathCp2;
    return keyframe;
  }

  static Keyframe<T> _parseStaticValue<T>(
      JsonReader reader, double scale, ValueParser<T> valueParser) {
    var value = valueParser(reader, scale: scale);
    return Keyframe<T>.nonAnimated(value);
  }
}
