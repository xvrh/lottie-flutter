import 'dart:ui';

import '../composition.dart';
import '../lottie_image_asset.dart';
import '../model/animatable/animatable_color_value.dart';
import '../model/content/content_model.dart';
import '../model/content/shape_fill.dart';
import '../model/content/shape_group.dart';
import '../model/content/shape_stroke.dart';
import '../model/font.dart';
import '../model/font_character.dart';
import '../model/layer/layer.dart';
import '../model/marker.dart';
import '../utils/misc.dart';
import '../value/keyframe.dart';
import 'color_parser.dart';
import 'font_character_parser.dart';
import 'font_parser.dart';
import 'layer_parser.dart';
import 'moshi/json_reader.dart';

class LottieCompositionParser {
  static final JsonReaderOptions _names = JsonReaderOptions.of([
    'w', // 0
    'h', // 1
    'ip', // 2
    'op', // 3
    'fr', // 4
    'v', // 5
    'layers', // 6
    'assets', // 7
    'fonts', // 8
    'chars', // 9
    'markers', // 10
    'slots', // 11
  ]);

  static LottieComposition parse(
    LottieComposition composition,
    JsonReader reader,
  ) {
    var parameters = CompositionParameters.forComposition(composition);

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          parameters.bounds.width = reader.nextDouble().toInt();
        case 1:
          parameters.bounds.height = reader.nextDouble().toInt();
        case 2:
          parameters.startFrame = reader.nextDouble();
        case 3:
          parameters.endFrame = reader.nextDouble() - 0.01;
        case 4:
          parameters.frameRate = reader.nextDouble();
        case 5:
          var version = reader.nextString();
          var versions = version.split('.');
          var majorVersion = int.parse(versions[0]);
          var minorVersion = int.parse(versions[1]);
          var patchVersion = int.parse(versions[2]);
          if (!MiscUtils.isAtLeastVersion(
            majorVersion,
            minorVersion,
            patchVersion,
            4,
            4,
            0,
          )) {
            composition.addWarning('Lottie only supports bodymovin >= 4.4.0');
          }
        case 6:
          _parseLayers(
            reader,
            composition,
            parameters.layers,
            parameters.layerMap,
          );
        case 7:
          _parseAssets(
            reader,
            composition,
            parameters.precomps,
            parameters.images,
          );
        case 8:
          _parseFonts(reader, parameters.fonts);
        case 9:
          _parseChars(reader, composition, parameters.characters);
        case 10:
          _parseMarkers(reader, composition, parameters.markers);
        case 11:
          _parseSlots(reader, composition, parameters.colorSlots);
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    assert(
      parameters.startFrame != parameters.endFrame,
      'startFrame == endFrame (${parameters.startFrame})',
    );
    assert(
      parameters.frameRate > 0,
      'invalid framerate: ${parameters.frameRate}',
    );

    _applySlots(composition, parameters);
    return composition;
  }

  static void _parseLayers(
    JsonReader reader,
    LottieComposition composition,
    List<Layer> layers,
    Map<int, Layer> layerMap,
  ) {
    var imageCount = 0;
    reader.beginArray();
    while (reader.hasNext()) {
      var layer = LayerParser.parseJson(reader, composition);
      if (layer.layerType == LayerType.image) {
        imageCount++;
      }
      layers.add(layer);
      layerMap[layer.id] = layer;
    }
    if (imageCount > 4) {
      composition.addWarning(
        'You have $imageCount images. Lottie should primarily be '
        'used with shapes. If you are using Adobe Illustrator, convert the Illustrator layers'
        ' to shape layers.',
      );
    }
    reader.endArray();
  }

  static final JsonReaderOptions _assetsNames = JsonReaderOptions.of([
    'id', // 0
    'layers', // 1
    'w', // 2
    'h', // 3
    'p', // 4
    'u', // 5
  ]);

  static void _parseAssets(
    JsonReader reader,
    LottieComposition composition,
    Map<String, List<Layer>> precomps,
    Map<String, LottieImageAsset> images,
  ) {
    reader.beginArray();
    while (reader.hasNext()) {
      late String id;
      // For precomps
      var layers = <Layer>[];
      var layerMap = <int, Layer>{};
      // For images
      var width = 0;
      var height = 0;
      String? imageFileName;
      String? relativeFolder;
      reader.beginObject();
      while (reader.hasNext()) {
        switch (reader.selectName(_assetsNames)) {
          case 0:
            id = reader.nextString();
          case 1:
            reader.beginArray();
            while (reader.hasNext()) {
              var layer = LayerParser.parseJson(reader, composition);
              layerMap[layer.id] = layer;
              layers.add(layer);
            }
            reader.endArray();
          case 2:
            width = reader.nextInt();
          case 3:
            height = reader.nextInt();
          case 4:
            imageFileName = reader.nextString();
          case 5:
            relativeFolder = reader.nextString();
          default:
            reader.skipName();
            reader.skipValue();
        }
      }
      reader.endObject();
      if (imageFileName != null) {
        var image = LottieImageAsset(
          width: width,
          height: height,
          id: id,
          fileName: imageFileName,
          dirName: relativeFolder ?? '',
        );
        images[image.id] = image;
      } else {
        precomps[id] = layers;
      }
    }
    reader.endArray();
  }

  static final JsonReaderOptions _fontNames = JsonReaderOptions.of(['list']);

  static void _parseFonts(JsonReader reader, Map<String, Font> fonts) {
    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_fontNames)) {
        case 0:
          reader.beginArray();
          while (reader.hasNext()) {
            var font = FontParser.parse(reader);
            fonts[font.name] = font;
          }
          reader.endArray();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();
  }

  static void _parseChars(
    JsonReader reader,
    LottieComposition composition,
    Map<int, FontCharacter> characters,
  ) {
    reader.beginArray();
    while (reader.hasNext()) {
      var character = FontCharacterParser.parse(reader, composition);
      characters[character.hashCode] = character;
    }
    reader.endArray();
  }

  static final JsonReaderOptions _markerNames = JsonReaderOptions.of([
    'cm',
    'tm',
    'dr',
  ]);

  static void _parseMarkers(
    JsonReader reader,
    LottieComposition composition,
    List<Marker> markers,
  ) {
    reader.beginArray();
    while (reader.hasNext()) {
      String? comment;
      var frame = 0.0;
      var durationFrames = 0.0;
      reader.beginObject();
      while (reader.hasNext()) {
        switch (reader.selectName(_markerNames)) {
          case 0:
            comment = reader.nextString();
          case 1:
            frame = reader.nextDouble();
          case 2:
            durationFrames = reader.nextDouble();
          default:
            reader.skipName();
            reader.skipValue();
        }
      }
      reader.endObject();
      markers.add(
        Marker(
          composition,
          comment ?? '',
          startFrame: frame,
          durationFrames: durationFrames,
        ),
      );
    }
    reader.endArray();
  }

  static final JsonReaderOptions _slotPropNames = JsonReaderOptions.of(['p']);

  static final JsonReaderOptions _slotInnerNames =
      JsonReaderOptions.of(['a', 'k']);

  static void _parseSlots(
    JsonReader reader,
    LottieComposition composition,
    Map<String, Color> out,
  ) {
    reader.beginObject();
    while (reader.hasNext()) {
      final slotId = reader.nextName();
      if (reader.peek() != Token.beginObject) {
        reader.skipValue();
        continue;
      }
      reader.beginObject();
      Color? parsed;
      var sawAnimated = false;
      while (reader.hasNext()) {
        switch (reader.selectName(_slotPropNames)) {
          case 0:
            final r = _readColorPropertyOrFlag(reader);
            parsed = r.color;
            sawAnimated = sawAnimated || r.animated;
          default:
            reader.skipName();
            reader.skipValue();
        }
      }
      reader.endObject();
      if (sawAnimated) {
        composition.addWarning(
          'Animated color slot "$slotId" is not yet supported; using static fallback.',
        );
      }
      if (parsed != null) {
        out[slotId] = parsed;
      }
    }
    reader.endObject();
  }

  static ({Color? color, bool animated}) _readColorPropertyOrFlag(
    JsonReader reader,
  ) {
    if (reader.peek() != Token.beginObject) {
      reader.skipValue();
      return (color: null, animated: false);
    }
    reader.beginObject();
    Color? color;
    var animated = false;
    while (reader.hasNext()) {
      switch (reader.selectName(_slotInnerNames)) {
        case 0:
          animated = reader.nextInt() == 1;
        case 1:
          if (!animated && reader.peek() == Token.beginArray) {
            color = colorParser(reader);
          } else {
            reader.skipValue();
          }
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();
    return (color: color, animated: animated);
  }

  static void _applySlots(
    LottieComposition composition,
    CompositionParameters parameters,
  ) {
    if (parameters.colorSlots.isEmpty) {
      return;
    }

    void visitLayer(Layer layer) {
      for (final shape in layer.shapes) {
        _walkColorValues(shape, parameters.colorSlots);
      }
    }

    for (final layer in parameters.layers) {
      visitLayer(layer);
    }
    for (final precomp in parameters.precomps.values) {
      for (final layer in precomp) {
        visitLayer(layer);
      }
    }
    for (final character in parameters.characters.values) {
      for (final shapeGroup in character.shapes) {
        _walkColorValues(shapeGroup, parameters.colorSlots);
      }
    }
  }

  static void _walkColorValues(
    ContentModel shape,
    Map<String, Color> slots,
  ) {
    if (shape is ShapeFill) {
      _maybeOverrideColor(shape.color, slots);
    } else if (shape is ShapeStroke) {
      _maybeOverrideColor(shape.color, slots);
    } else if (shape is ShapeGroup) {
      for (final inner in shape.items) {
        _walkColorValues(inner, slots);
      }
    }
  }

  static void _maybeOverrideColor(
    AnimatableColorValue? color,
    Map<String, Color> slots,
  ) {
    final sid = color?.slotId;
    if (sid == null) {
      return;
    }
    final slotColor = slots[sid];
    if (slotColor == null) {
      return;
    }
    color!
      ..keyframes.clear()
      ..keyframes.add(Keyframe.nonAnimated(slotColor))
      ..slotId = null;
  }
}
