import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'frame_rate.dart';
import 'lottie_image_asset.dart';
import 'model/font.dart';
import 'model/font_character.dart';
import 'model/layer/layer.dart';
import 'model/marker.dart';
import 'parser/lottie_composition_parser.dart';
import 'parser/moshi/json_reader.dart';
import 'performance_tracker.dart';
import 'providers/load_image.dart';
import 'utils.dart';

typedef WarningCallback = void Function(String);

class CompositionParameters {
  MutableRectangle<int> bounds = MutableRectangle<int>(0, 0, 0, 0);
  double startFrame = 0.0;
  double endFrame = 0;
  double frameRate = 0;
  final layers = <Layer>[];
  final layerMap = <int, Layer>{};
  final precomps = <String, List<Layer>>{};
  final images = <String, LottieImageAsset>{};
  final characters = <int, FontCharacter>{};
  final fonts = <String, Font>{};
  final markers = <Marker>[];

  static CompositionParameters forComposition(LottieComposition composition) =>
      composition._parameters;
}

class LottieComposition {
  static Future<LottieComposition> fromByteData(ByteData data,
      {String? name, LottieImageProviderFactory? imageProviderFactory}) {
    return fromBytes(data.buffer.asUint8List(),
        name: name, imageProviderFactory: imageProviderFactory);
  }

  static Future<LottieComposition> fromBytes(Uint8List bytes,
      {String? name, LottieImageProviderFactory? imageProviderFactory}) async {
    Archive? archive;
    if (bytes[0] == 0x50 && bytes[1] == 0x4B) {
      archive = ZipDecoder().decodeBytes(bytes);
      var jsonFile = archive.files.firstWhere((e) => e.name.endsWith('.json'));
      bytes = jsonFile.content as Uint8List;
    }

    var composition = LottieCompositionParser.parse(
        LottieComposition._(name), JsonReader.fromBytes(bytes));

    if (archive != null) {
      for (var image in composition.images.values) {
        var imagePath = p.posix.join(image.dirName, image.fileName);
        var found = archive.files.firstWhereOrNull(
            (f) => f.name.toLowerCase() == imagePath.toLowerCase());

        ImageProvider? provider;
        if (imageProviderFactory != null) {
          provider = imageProviderFactory(image);
        }

        if (provider != null) {
          image.loadedImage = await loadImage(composition, image, provider);
        }

        if (found != null) {
          image.loadedImage ??= await loadImage(
              composition, image, MemoryImage(found.content as Uint8List));
        }
      }
    }

    return composition;
  }

  LottieComposition._(this.name);

  final String? name;
  final _performanceTracker = PerformanceTracker();
  // This is stored as a set to avoid duplicates.
  final _warnings = <String>{};

  /// Map of font names to fonts */
  final _parameters = CompositionParameters();

  /// Used to determine if an animation can be drawn with hardware acceleration.
  bool hasDashPattern = false;

  /// Counts the number of mattes and masks. Before Android switched to SKIA
  /// for drawing in Oreo (API 28), using hardware acceleration with mattes and masks
  /// was only faster until you had ~4 masks after which it would actually become slower.
  int _maskAndMatteCount = 0;

  WarningCallback? onWarning;

  void addWarning(String warning) {
    var isNew = _warnings.add(warning);
    if (isNew) {
      onWarning?.call(warning);
    }
  }

  void incrementMatteOrMaskCount(int amount) {
    _maskAndMatteCount += amount;
  }

  /// Used to determine if an animation can be drawn with hardware acceleration.
  int get maskAndMatteCount => _maskAndMatteCount;

  List<String> get warnings => _warnings.toList();

  bool get performanceTrackingEnabled => _performanceTracker.enabled;
  set performanceTrackingEnabled(bool enabled) {
    _performanceTracker.enabled = enabled;
  }

  PerformanceTracker get performanceTracker => _performanceTracker;

  Layer? layerModelForId(int id) {
    return _parameters.layerMap[id];
  }

  Rectangle<int> get bounds => _parameters.bounds;

  Duration get duration {
    return Duration(milliseconds: (seconds * 1000).round());
  }

  double get seconds => durationFrames / frameRate;

  double get startFrame => _parameters.startFrame;

  double get endFrame => _parameters.endFrame;

  double get frameRate => _parameters.frameRate;

  List<Layer> get layers => _parameters.layers;

  List<Layer>? getPrecomps(String? id) {
    return _parameters.precomps[id];
  }

  Map<int, FontCharacter> get characters => _parameters.characters;

  Map<String, Font> get fonts => _parameters.fonts;

  List<Marker> get markers => _parameters.markers;

  Marker? getMarker(String markerName) {
    for (var i = 0; i < markers.length; i++) {
      var marker = markers[i];
      if (marker.matchesName(markerName)) {
        return marker;
      }
    }
    return null;
  }

  bool get hasImages {
    return images.isNotEmpty;
  }

  Map<String, LottieImageAsset> get images {
    return _parameters.images;
  }

  double get durationFrames {
    return endFrame - startFrame;
  }

  /// Returns a "rounded" progress value according to the frameRate
  double roundProgress(double progress, {required FrameRate frameRate}) {
    num? fps;
    if (frameRate == FrameRate.max) {
      return progress;
    } else if (frameRate == FrameRate.composition) {
      fps = this.frameRate;
    }
    fps ??= frameRate.framesPerSecond;

    var totalFrameCount = seconds * fps;
    var frameIndex = (totalFrameCount * progress).toInt();
    var roundedProgress = frameIndex / totalFrameCount;
    assert(roundedProgress >= 0 && roundedProgress <= 1,
        'Progress is $roundedProgress');
    return roundedProgress;
  }

  @override
  String toString() {
    final sb = StringBuffer('LottieComposition:\n');
    for (var layer in layers) {
      sb.write(layer.toStringWithPrefix('\t'));
    }
    return sb.toString();
  }
}
