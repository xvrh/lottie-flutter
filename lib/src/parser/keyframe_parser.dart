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
  static const _maxCpValue = 100.0;
  static const _linearInterpolator = Curves.linear;
  static final _pathInterpolatorCache = <int, Curve>{};

  static final JsonReaderOptions _names =
      JsonReaderOptions.of(['t', 's', 'e', 'o', 'i', 'h', 'to', 'ti']);

  static final JsonReaderOptions _interpolatorNames = JsonReaderOptions.of([
    'x', // 1
    'y' // 2
  ]);

  /// @param multiDimensional When true, the keyframe interpolators can be independent for the X and Y axis.
  static Keyframe<T> parse<T>(JsonReader reader, LottieComposition composition,
      ValueParser<T> valueParser,
      {required bool animated, bool multiDimensional = false}) {
    if (animated && multiDimensional) {
      return _parseMultiDimensionalKeyframe(composition, reader, valueParser);
    } else if (animated) {
      return _parseKeyframe(composition, reader, valueParser);
    } else {
      return _parseStaticValue(reader, valueParser);
    }
  }

  /// beginObject will already be called on the keyframe so it can be differentiated with
  /// a non animated value.
  static Keyframe<T> _parseKeyframe<T>(LottieComposition composition,
      JsonReader reader, ValueParser<T> valueParser) {
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
        case 1:
          startValue = valueParser(reader);
        case 2:
          endValue = valueParser(reader);
        case 3:
          cp1 = JsonUtils.jsonToPoint(reader);
        case 4:
          cp2 = JsonUtils.jsonToPoint(reader);
        case 5:
          hold = reader.nextInt() == 1;
        case 6:
          pathCp1 = JsonUtils.jsonToPoint(reader);
        case 7:
          pathCp2 = JsonUtils.jsonToPoint(reader);
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
      interpolator = _interpolatorFor(cp1, cp2);
    } else {
      interpolator = _linearInterpolator;
    }

    var keyframe = Keyframe<T>(
      composition,
      startValue: startValue,
      endValue: endValue,
      interpolator: interpolator,
      startFrame: startFrame,
    );
    keyframe.pathCp1 = pathCp1;
    keyframe.pathCp2 = pathCp2;
    return keyframe;
  }

  static Keyframe<T> _parseMultiDimensionalKeyframe<T>(
      LottieComposition composition,
      JsonReader reader,
      ValueParser<T> valueParser) {
    Offset? cp1;
    Offset? cp2;

    Offset? xCp1;
    Offset? xCp2;
    Offset? yCp1;
    Offset? yCp2;

    var startFrame = 0.0;
    T? startValue;
    T? endValue;
    var hold = false;
    Curve? interpolator;
    Curve? xInterpolator;
    Curve? yInterpolator;

    // Only used by PathKeyframe
    Offset? pathCp1;
    Offset? pathCp2;

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0: // t
          startFrame = reader.nextDouble();
        case 1: // s
          startValue = valueParser(reader);
        case 2: // e
          endValue = valueParser(reader);
        case 3: // o
          if (reader.peek() == Token.beginObject) {
            reader.beginObject();
            var xCp1x = 0.0;
            var xCp1y = 0.0;
            var yCp1x = 0.0;
            var yCp1y = 0.0;
            while (reader.hasNext()) {
              switch (reader.selectName(_interpolatorNames)) {
                case 0: // x
                  if (reader.peek() == Token.number) {
                    xCp1x = reader.nextDouble();
                    yCp1x = xCp1x;
                  } else {
                    reader.beginArray();
                    xCp1x = reader.nextDouble();
                    if (reader.peek() == Token.number) {
                      yCp1x = reader.nextDouble();
                    } else {
                      yCp1x = xCp1x;
                    }
                    reader.endArray();
                  }
                case 1: // y
                  if (reader.peek() == Token.number) {
                    xCp1y = reader.nextDouble();
                    yCp1y = xCp1y;
                  } else {
                    reader.beginArray();
                    xCp1y = reader.nextDouble();
                    if (reader.peek() == Token.number) {
                      yCp1y = reader.nextDouble();
                    } else {
                      yCp1y = xCp1y;
                    }
                    reader.endArray();
                  }
                default:
                  reader.skipValue();
              }
            }
            xCp1 = Offset(xCp1x, xCp1y);
            yCp1 = Offset(yCp1x, yCp1y);
            reader.endObject();
          } else {
            cp1 = JsonUtils.jsonToPoint(reader);
          }
        case 4: // i
          if (reader.peek() == Token.beginObject) {
            reader.beginObject();
            var xCp2x = 0.0;
            var xCp2y = 0.0;
            var yCp2x = 0.0;
            var yCp2y = 0.0;
            while (reader.hasNext()) {
              switch (reader.selectName(_interpolatorNames)) {
                case 0: // x
                  if (reader.peek() == Token.number) {
                    xCp2x = reader.nextDouble();
                    yCp2x = xCp2x;
                  } else {
                    reader.beginArray();
                    xCp2x = reader.nextDouble();
                    if (reader.peek() == Token.number) {
                      yCp2x = reader.nextDouble();
                    } else {
                      yCp2x = xCp2x;
                    }
                    reader.endArray();
                  }
                case 1: // y
                  if (reader.peek() == Token.number) {
                    xCp2y = reader.nextDouble();
                    yCp2y = xCp2y;
                  } else {
                    reader.beginArray();
                    xCp2y = reader.nextDouble();
                    if (reader.peek() == Token.number) {
                      yCp2y = reader.nextDouble();
                    } else {
                      yCp2y = xCp2y;
                    }
                    reader.endArray();
                  }
                default:
                  reader.skipValue();
              }
            }
            xCp2 = Offset(xCp2x, xCp2y);
            yCp2 = Offset(yCp2x, yCp2y);
            reader.endObject();
          } else {
            cp2 = JsonUtils.jsonToPoint(reader);
          }
        case 5: // h
          hold = reader.nextInt() == 1;
        case 6: // to
          pathCp1 = JsonUtils.jsonToPoint(reader);
        case 7: // ti
          pathCp2 = JsonUtils.jsonToPoint(reader);
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
      interpolator = _interpolatorFor(cp1, cp2);
    } else if (xCp1 != null && yCp1 != null && xCp2 != null && yCp2 != null) {
      xInterpolator = _interpolatorFor(xCp1, xCp2);
      yInterpolator = _interpolatorFor(yCp1, yCp2);
    } else {
      interpolator = _linearInterpolator;
    }

    Keyframe<T> keyframe;
    if (xInterpolator != null && yInterpolator != null) {
      keyframe = Keyframe<T>(composition,
          startValue: startValue,
          endValue: endValue,
          xInterpolator: xInterpolator,
          yInterpolator: yInterpolator,
          startFrame: startFrame);
    } else {
      keyframe = Keyframe<T>(composition,
          startValue: startValue,
          endValue: endValue,
          interpolator: interpolator,
          startFrame: startFrame);
    }

    keyframe.pathCp1 = pathCp1;
    keyframe.pathCp2 = pathCp2;
    return keyframe;
  }

  static Curve _interpolatorFor(Offset cp1, Offset cp2) {
    Curve interpolator;
    cp1 = Offset(cp1.dx.clamp(-1, 1), cp1.dy.clamp(-_maxCpValue, _maxCpValue));
    cp2 = Offset(cp2.dx.clamp(-1, 1), cp2.dy.clamp(-_maxCpValue, _maxCpValue));
    var hash = Utils.hashFor(cp1.dx, cp1.dy, cp2.dx, cp2.dy);

    interpolator = _pathInterpolatorCache.putIfAbsent(hash, () {
      try {
        return PathInterpolator.cubic(cp1.dx, cp1.dy, cp2.dx, cp2.dy);
      } catch (e) {
        debugPrint('DEBUG: Path interpolator error $e');
        //TODO(xha): check the error message for Flutter
        if ('$e'.contains('The Path cannot loop back on itself.')) {
          // If a control point extends beyond the previous/next point then it will cause the value of the interpolator to no
          // longer monotonously increase. This clips the control point bounds to prevent that from happening.
          // NOTE: this will make the rendered animation behave slightly differently than the original.
          return PathInterpolator.cubic(
              min(cp1.dx, 1.0), cp1.dy, max(cp2.dx, 0.0), cp2.dy);
        } else {
          // We failed to create the interpolator. Fall back to linear.
          return Curves.linear;
        }
      }
    });
    return interpolator;
  }

  static Keyframe<T> _parseStaticValue<T>(
      JsonReader reader, ValueParser<T> valueParser) {
    var value = valueParser(reader);
    return Keyframe<T>.nonAnimated(value);
  }
}
