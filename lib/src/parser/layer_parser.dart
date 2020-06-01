import 'dart:ui';
import '../composition.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_text_frame.dart';
import '../model/animatable/animatable_text_properties.dart';
import '../model/animatable/animatable_transform.dart';
import '../model/content/content_model.dart';
import '../model/content/mask.dart';
import '../model/layer/layer.dart';
import '../utils/misc.dart';
import '../value/keyframe.dart';
import 'animatable_text_properties_parser.dart';
import 'animatable_transform_parser.dart';
import 'animatable_value_parser.dart';
import 'content_model_parser.dart';
import 'mask_parser.dart';
import 'moshi/json_reader.dart';

class LayerParser {
  LayerParser._();

  static final JsonReaderOptions _names = JsonReaderOptions.of([
    'nm', // 0
    'ind', // 1
    'refId', // 2
    'ty', // 3
    'parent', // 4
    'sw', // 5
    'sh', // 6
    'sc', // 7
    'ks', // 8
    'tt', // 9
    'masksProperties', // 10
    'shapes', // 11
    't', // 12
    'ef', // 13
    'sr', // 14
    'st', // 15
    'w', // 16
    'h', // 17
    'ip', // 18
    'op', // 19
    'tm', // 20
    'cl', // 21
    'hd' // 22
  ]);

  static Layer parse(LottieComposition composition) {
    var bounds = composition.bounds;
    return Layer(
        shapes: <ContentModel>[],
        composition: composition,
        name: '__container',
        id: -1,
        layerType: LayerType.preComp,
        parentId: -1,
        refId: null,
        masks: <Mask>[],
        transform: AnimatableTransform(),
        solidWidth: 0,
        solidHeight: 0,
        solidColor: Color(0),
        timeStretch: 0,
        startFrame: 0,
        preCompWidth: bounds.width,
        preCompHeight: bounds.height,
        text: null,
        textProperties: null,
        inOutKeyframes: <Keyframe<double>>[],
        matteType: MatteType.none,
        timeRemapping: null,
        isHidden: false);
  }

  static final JsonReaderOptions _textNames = JsonReaderOptions.of(['d', 'a']);

  static final JsonReaderOptions _effectsNames = JsonReaderOptions.of(['nm']);

  static Layer parseJson(JsonReader reader, LottieComposition composition) {
    // This should always be set by After Effects. However, if somebody wants to minify
    // and optimize their json, the name isn't critical for most cases so it can be removed.
    var layerName = 'UNSET';
    LayerType layerType;
    String refId;
    var layerId = 0;
    var solidWidth = 0;
    var solidHeight = 0;
    var solidColor = Color(0);
    var preCompWidth = 0;
    var preCompHeight = 0;
    var parentId = -1;
    var timeStretch = 1.0;
    var startFrame = 0.0;
    var inFrame = 0.0;
    var outFrame = 0.0;
    String cl;
    var hidden = false;

    var matteType = MatteType.none;
    AnimatableTransform transform;
    AnimatableTextFrame text;
    AnimatableTextProperties textProperties;
    AnimatableDoubleValue timeRemapping;

    var masks = <Mask>[];
    var shapes = <ContentModel>[];

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          layerName = reader.nextString();
          break;
        case 1:
          layerId = reader.nextInt();
          break;
        case 2:
          refId = reader.nextString();
          break;
        case 3:
          var layerTypeInt = reader.nextInt();
          if (layerTypeInt < LayerType.unknown.index) {
            layerType = LayerType.values[layerTypeInt];
          } else {
            print('Unknown $layerTypeInt');
            layerType = LayerType.unknown;
          }
          break;
        case 4:
          parentId = reader.nextInt();
          break;
        case 5:
          solidWidth = (reader.nextInt() * window.devicePixelRatio).round();
          break;
        case 6:
          solidHeight = (reader.nextInt() * window.devicePixelRatio).round();
          break;
        case 7:
          solidColor = MiscUtils.parseColor(reader.nextString(),
              warningCallback: composition.addWarning);
          break;
        case 8:
          transform = AnimatableTransformParser.parse(reader, composition);
          break;
        case 9:
          matteType = MatteType.values[reader.nextInt()];
          composition.incrementMatteOrMaskCount(1);
          break;
        case 10:
          reader.beginArray();
          while (reader.hasNext()) {
            masks.add(MaskParser.parse(reader, composition));
          }
          composition.incrementMatteOrMaskCount(masks.length);
          reader.endArray();
          break;
        case 11:
          reader.beginArray();
          while (reader.hasNext()) {
            var shape = ContentModelParser.parse(reader, composition);
            if (shape != null) {
              shapes.add(shape);
            }
          }
          reader.endArray();
          break;
        case 12:
          reader.beginObject();
          while (reader.hasNext()) {
            switch (reader.selectName(_textNames)) {
              case 0:
                text = AnimatableValueParser.parseDocumentData(
                    reader, composition);
                break;
              case 1:
                reader.beginArray();
                if (reader.hasNext()) {
                  textProperties =
                      AnimatableTextPropertiesParser.parse(reader, composition);
                }
                while (reader.hasNext()) {
                  reader.skipValue();
                }
                reader.endArray();
                break;
              default:
                reader.skipName();
                reader.skipValue();
            }
          }
          reader.endObject();
          break;
        case 13:
          reader.beginArray();
          var effectNames = <String>[];
          while (reader.hasNext()) {
            reader.beginObject();
            while (reader.hasNext()) {
              switch (reader.selectName(_effectsNames)) {
                case 0:
                  effectNames.add(reader.nextString());
                  break;
                default:
                  reader.skipName();
                  reader.skipValue();
              }
            }
            reader.endObject();
          }
          reader.endArray();
          composition.addWarning(
              "Lottie doesn't support layer effects. If you are using them for "
              ' fills, strokes, trim paths etc. then try adding them directly as contents '
              ' in your shape. Found: $effectNames');
          break;
        case 14:
          timeStretch = reader.nextDouble();
          break;
        case 15:
          startFrame = reader.nextDouble();
          break;
        case 16:
          preCompWidth = (reader.nextInt() * window.devicePixelRatio).round();
          break;
        case 17:
          preCompHeight = (reader.nextInt() * window.devicePixelRatio).round();
          break;
        case 18:
          inFrame = reader.nextDouble();
          break;
        case 19:
          outFrame = reader.nextDouble();
          break;
        case 20:
          timeRemapping = AnimatableValueParser.parseFloat(reader, composition,
              isDp: false);
          break;
        case 21:
          cl = reader.nextString();
          break;
        case 22:
          hidden = reader.nextBoolean();
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    // Bodymovin pre-scales the in frame and out frame by the time stretch. However, that will
    // cause the stretch to be double counted since the in out animation gets treated the same
    // as all other animations and will have stretch applied to it again.
    inFrame /= timeStretch;
    outFrame /= timeStretch;

    var inOutKeyframes = <Keyframe<double>>[];
    // Before the in frame
    if (inFrame > 0) {
      var preKeyframe = Keyframe<double>(composition,
          startValue: 0.0,
          endValue: 0.0,
          interpolator: null,
          startFrame: 0.0,
          endFrame: inFrame);
      inOutKeyframes.add(preKeyframe);
    }

    // The + 1 is because the animation should be visible on the out frame itself.
    outFrame = outFrame > 0 ? outFrame : composition.endFrame;
    var visibleKeyframe = Keyframe<double>(composition,
        startValue: 1.0,
        endValue: 1.0,
        interpolator: null,
        startFrame: inFrame,
        endFrame: outFrame);
    inOutKeyframes.add(visibleKeyframe);

    var outKeyframe = Keyframe<double>(composition,
        startValue: 0.0,
        endValue: 0.0,
        interpolator: null,
        startFrame: outFrame,
        endFrame: double.maxFinite);
    inOutKeyframes.add(outKeyframe);

    if (layerName.endsWith('.ai') || 'ai' == cl) {
      composition
          .addWarning('Convert your Illustrator layers to shape layers.');
    }

    return Layer(
        shapes: shapes,
        composition: composition,
        name: layerName,
        id: layerId,
        layerType: layerType,
        parentId: parentId,
        refId: refId,
        masks: masks,
        transform: transform,
        solidWidth: solidWidth,
        solidHeight: solidHeight,
        solidColor: solidColor,
        timeStretch: timeStretch,
        startFrame: startFrame,
        preCompWidth: preCompWidth,
        preCompHeight: preCompHeight,
        text: text,
        textProperties: textProperties,
        inOutKeyframes: inOutKeyframes,
        matteType: matteType,
        timeRemapping: timeRemapping,
        isHidden: hidden);
  }
}
