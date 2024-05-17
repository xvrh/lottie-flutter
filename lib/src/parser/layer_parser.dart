import 'dart:ui';
import '../composition.dart';
import '../model/animatable/animatable_double_value.dart';
import '../model/animatable/animatable_text_frame.dart';
import '../model/animatable/animatable_text_properties.dart';
import '../model/animatable/animatable_transform.dart';
import '../model/content/blur_effect.dart';
import '../model/content/content_model.dart';
import '../model/content/drop_shadow_effect.dart';
import '../model/content/layer_blend.dart';
import '../model/content/mask.dart';
import '../model/layer/layer.dart';
import '../utils/misc.dart';
import '../value/keyframe.dart';
import 'animatable_text_properties_parser.dart';
import 'animatable_transform_parser.dart';
import 'animatable_value_parser.dart';
import 'blur_effect_parser.dart';
import 'content_model_parser.dart';
import 'drop_shadow_effect_parser.dart';
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
    'hd', // 22
    'ao', // 23
    'bm', // 24
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
      masks: <Mask>[],
      transform: AnimatableTransform(),
      solidWidth: 0,
      solidHeight: 0,
      solidColor: const Color(0x00000000),
      timeStretch: 0,
      startFrame: 0,
      preCompWidth: bounds.width,
      preCompHeight: bounds.height,
      inOutKeyframes: <Keyframe<double>>[],
      matteType: MatteType.none,
      isHidden: false,
    );
  }

  static final JsonReaderOptions _textNames = JsonReaderOptions.of(['d', 'a']);

  static final JsonReaderOptions _effectsNames =
      JsonReaderOptions.of(['ty', 'nm']);

  static Layer parseJson(JsonReader reader, LottieComposition composition) {
    // This should always be set by After Effects. However, if somebody wants to minify
    // and optimize their json, the name isn't critical for most cases so it can be removed.
    var layerName = 'UNSET';
    var layerType = LayerType.unknown;
    String? refId;
    var layerId = 0;
    var solidWidth = 0;
    var solidHeight = 0;
    var solidColor = const Color(0x00000000);
    var preCompWidth = 0;
    var preCompHeight = 0;
    var parentId = -1;
    var timeStretch = 1.0;
    var startFrame = 0.0;
    var inFrame = 0.0;
    var outFrame = 0.0;
    String? cl;
    var hidden = false;
    BlurEffect? blurEffect;
    DropShadowEffect? dropShadowEffect;
    var autoOrient = false;

    var matteType = MatteType.none;
    BlendMode? blendMode;
    AnimatableTransform? transform;
    AnimatableTextFrame? text;
    AnimatableTextProperties? textProperties;
    AnimatableDoubleValue? timeRemapping;

    var masks = <Mask>[];
    var shapes = <ContentModel>[];

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          layerName = reader.nextString();
        case 1:
          layerId = reader.nextInt();
        case 2:
          refId = reader.nextString();
        case 3:
          var layerTypeInt = reader.nextInt();
          if (layerTypeInt < LayerType.unknown.index) {
            layerType = LayerType.values[layerTypeInt];
          } else {
            layerType = LayerType.unknown;
          }
        case 4:
          parentId = reader.nextInt();
        case 5:
          solidWidth = reader.nextInt();
        case 6:
          solidHeight = reader.nextInt();
        case 7:
          solidColor = MiscUtils.parseColor(reader.nextString(),
              warningCallback: composition.addWarning);
        case 8:
          transform = AnimatableTransformParser.parse(reader, composition);
        case 9:
          var matteTypeIndex = reader.nextInt();
          if (matteTypeIndex >= MatteType.values.length) {
            composition.addWarning('Unsupported matte type: $matteTypeIndex');
            break;
          }
          matteType = MatteType.values[matteTypeIndex];
          if (matteType == MatteType.luma) {
            composition.addWarning('Unsupported matte type: Luma');
          } else if (matteType == MatteType.lumaInverted) {
            composition.addWarning('Unsupported matte type: Luma Inverted');
          }
          composition.incrementMatteOrMaskCount(1);
        case 10:
          reader.beginArray();
          while (reader.hasNext()) {
            masks.add(MaskParser.parse(reader, composition));
          }
          composition.incrementMatteOrMaskCount(masks.length);
          reader.endArray();
        case 11:
          reader.beginArray();
          while (reader.hasNext()) {
            var shape = ContentModelParser.parse(reader, composition);
            if (shape != null) {
              shapes.add(shape);
            }
          }
          reader.endArray();
        case 12:
          reader.beginObject();
          while (reader.hasNext()) {
            switch (reader.selectName(_textNames)) {
              case 0:
                text = AnimatableValueParser.parseDocumentData(
                    reader, composition);
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
              default:
                reader.skipName();
                reader.skipValue();
            }
          }
          reader.endObject();
        case 13:
          reader.beginArray();
          var effectNames = <String>[];
          while (reader.hasNext()) {
            reader.beginObject();
            while (reader.hasNext()) {
              switch (reader.selectName(_effectsNames)) {
                case 0:
                  var type = reader.nextInt();
                  if (type == 29) {
                    blurEffect = BlurEffectParser.parse(reader, composition);
                  } else if (type == 25) {
                    dropShadowEffect =
                        DropShadowEffectParser().parse(reader, composition);
                  }
                case 1:
                  var effectName = reader.nextString();
                  effectNames.add(effectName);
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
        case 14:
          timeStretch = reader.nextDouble();
        case 15:
          startFrame = reader.nextDouble();
        case 16:
          preCompWidth = reader.nextDouble().toInt();
        case 17:
          preCompHeight = reader.nextDouble().toInt();
        case 18:
          inFrame = reader.nextDouble();
        case 19:
          outFrame = reader.nextDouble();
        case 20:
          timeRemapping = AnimatableValueParser.parseFloat(reader, composition);
        case 21:
          cl = reader.nextString();
        case 22:
          hidden = reader.nextBoolean();
        case 23:
          autoOrient = reader.nextInt() == 1;
        case 24:
          var blendModeIndex = reader.nextInt();
          if (blendModeIndex >= blendModes.length) {
            composition.addWarning('Unsupported Blend Mode: $blendModeIndex');
            break;
          }
          blendMode = blendModes[blendModeIndex];
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();

    var inOutKeyframes = <Keyframe<double>>[];
    // Before the in frame
    if (inFrame > 0) {
      var preKeyframe = Keyframe<double>(composition,
          startValue: 0.0, endValue: 0.0, startFrame: 0.0, endFrame: inFrame);
      inOutKeyframes.add(preKeyframe);
    }

    outFrame = outFrame > 0 ? outFrame : composition.endFrame;
    var visibleKeyframe = Keyframe<double>(composition,
        startValue: 1.0,
        endValue: 1.0,
        startFrame: inFrame,
        endFrame: outFrame);
    inOutKeyframes.add(visibleKeyframe);

    var outKeyframe = Keyframe<double>(composition,
        startValue: 0.0,
        endValue: 0.0,
        startFrame: outFrame,
        endFrame: double.maxFinite);
    inOutKeyframes.add(outKeyframe);

    if (layerName.endsWith('.ai') || 'ai' == cl) {
      composition
          .addWarning('Convert your Illustrator layers to shape layers.');
    }
    if (autoOrient) {
      transform ??= AnimatableTransform();
      transform.isAutoOrient = autoOrient;
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
      transform: transform!,
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
      isHidden: hidden,
      blurEffect: blurEffect,
      dropShadowEffect: dropShadowEffect,
      blendMode: blendMode,
    );
  }
}
