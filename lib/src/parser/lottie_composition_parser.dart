import 'dart:math';
import 'dart:ui';
import '../composition.dart';
import '../lottie_image_asset.dart';
import '../model/font.dart';
import '../model/font_character.dart';
import '../model/layer/layer.dart';
import '../model/marker.dart';
import '../utils/misc.dart';
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
    'markers' // 10
  ]);

  static LottieComposition parse(
      LottieComposition composition, JsonReader reader) {
    var scale = window.devicePixelRatio;
    var startFrame = 0.0;
    var endFrame = 0.0;
    var frameRate = 0.0;
    final layerMap = <int, Layer>{};
    final layers = <Layer>[];
    var width = 0;
    var height = 0;
    var precomps = <String, List<Layer>>{};
    var images = <String, LottieImageAsset>{};
    var fonts = <String, Font>{};
    var markers = <Marker>[];
    var characters = <int, FontCharacter>{};

    reader.beginObject();
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          width = reader.nextInt();
          break;
        case 1:
          height = reader.nextInt();
          break;
        case 2:
          startFrame = reader.nextDouble();
          break;
        case 3:
          endFrame = reader.nextDouble() - 0.01;
          break;
        case 4:
          frameRate = reader.nextDouble();
          break;
        case 5:
          var version = reader.nextString();
          var versions = version.split('.');
          var majorVersion = int.parse(versions[0]);
          var minorVersion = int.parse(versions[1]);
          var patchVersion = int.parse(versions[2]);
          if (!MiscUtils.isAtLeastVersion(
              majorVersion, minorVersion, patchVersion, 4, 4, 0)) {
            composition.addWarning('Lottie only supports bodymovin >= 4.4.0');
          }
          break;
        case 6:
          _parseLayers(reader, composition, layers, layerMap);
          break;
        case 7:
          _parseAssets(reader, composition, precomps, images);
          break;
        case 8:
          _parseFonts(reader, fonts);
          break;
        case 9:
          _parseChars(reader, composition, characters);
          break;
        case 10:
          _parseMarkers(reader, composition, markers);
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    var scaledWidth = (width * scale).round();
    var scaledHeight = (height * scale).round();
    var bounds = Rectangle<int>(0, 0, scaledWidth, scaledHeight);

    internalInit(composition, bounds, startFrame, endFrame, frameRate, layers,
        layerMap, precomps, images, characters, fonts, markers);

    return composition;
  }

  static void _parseLayers(JsonReader reader, LottieComposition composition,
      List<Layer> layers, Map<int, Layer> layerMap) {
    var imageCount = 0;
    reader.beginArray();
    while (reader.hasNext()) {
      var layer = LayerParser.parseJson(reader, composition);
      if (layer.layerType == LayerType.image) {
        imageCount++;
      }
      layers.add(layer);
      layerMap[layer.id] = layer;

      if (imageCount > 4) {
        composition.addWarning(
            'You have $imageCount images. Lottie should primarily be '
            'used with shapes. If you are using Adobe Illustrator, convert the Illustrator layers'
            ' to shape layers.');
      }
    }
    reader.endArray();
  }

  static final JsonReaderOptions _assetsNames = JsonReaderOptions.of([
    'id', // 0
    'layers', // 1
    'w', // 2
    'h', // 3
    'p', // 4
    'u' // 5
  ]);

  static void _parseAssets(JsonReader reader, LottieComposition composition,
      Map<String, List<Layer>> precomps, Map<String, LottieImageAsset> images) {
    reader.beginArray();
    while (reader.hasNext()) {
      String id;
      // For precomps
      var layers = <Layer>[];
      var layerMap = <int, Layer>{};
      // For images
      var width = 0;
      var height = 0;
      String imageFileName;
      String relativeFolder;
      reader.beginObject();
      while (reader.hasNext()) {
        switch (reader.selectName(_assetsNames)) {
          case 0:
            id = reader.nextString();
            break;
          case 1:
            reader.beginArray();
            while (reader.hasNext()) {
              var layer = LayerParser.parseJson(reader, composition);
              layerMap[layer.id] = layer;
              layers.add(layer);
            }
            reader.endArray();
            break;
          case 2:
            width = reader.nextInt();
            break;
          case 3:
            height = reader.nextInt();
            break;
          case 4:
            imageFileName = reader.nextString();
            break;
          case 5:
            relativeFolder = reader.nextString();
            break;
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
            dirName: relativeFolder);
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
          break;
        default:
          reader.skipName();
          reader.skipValue();
      }
    }
    reader.endObject();
  }

  static void _parseChars(JsonReader reader, LottieComposition composition,
      Map<int, FontCharacter> characters) {
    reader.beginArray();
    while (reader.hasNext()) {
      var character = FontCharacterParser.parse(reader, composition);
      characters[character.hashCode] = character;
    }
    reader.endArray();
  }

  static final JsonReaderOptions _markerNames =
      JsonReaderOptions.of(['cm', 'tm', 'dr']);

  static void _parseMarkers(
      JsonReader reader, LottieComposition composition, List<Marker> markers) {
    reader.beginArray();
    while (reader.hasNext()) {
      String comment;
      var frame = 0.0;
      var durationFrames = 0.0;
      reader.beginObject();
      while (reader.hasNext()) {
        switch (reader.selectName(_markerNames)) {
          case 0:
            comment = reader.nextString();
            break;
          case 1:
            frame = reader.nextDouble();
            break;
          case 2:
            durationFrames = reader.nextDouble();
            break;
          default:
            reader.skipName();
            reader.skipValue();
        }
      }
      reader.endObject();
      markers.add(Marker(composition, comment,
          startFrame: frame, durationFrames: durationFrames));
    }
    reader.endArray();
  }
}
