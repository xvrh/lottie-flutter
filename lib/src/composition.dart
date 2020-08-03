import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'frame_rate.dart';
import 'logger.dart';
import 'lottie_image_asset.dart';
import 'model/font.dart';
import 'model/font_character.dart';
import 'model/layer/layer.dart';
import 'model/marker.dart';
import 'parser/lottie_composition_parser.dart';
import 'parser/moshi/json_reader.dart';
import 'performance_tracker.dart';
import 'providers/load_image.dart';

void internalInit(
    LottieComposition composition,
    Rectangle<int> bounds,
    double startFrame,
    double endFrame,
    double frameRate,
    List<Layer> layers,
    Map<int, Layer> layerMap,
    Map<String, List<Layer>> precomps,
    Map<String, LottieImageAsset> images,
    Map<int, FontCharacter> characters,
    Map<String, Font> fonts,
    List<Marker> markers) {
  assert(startFrame != endFrame, 'startFrame == endFrame ($startFrame)');
  assert(frameRate > 0, 'invalid framerate: $frameRate');
  composition
    .._bounds = bounds
    .._startFrame = startFrame
    .._endFrame = endFrame
    .._frameRate = frameRate
    .._layers = layers
    .._layerMap = layerMap
    .._precomps = precomps
    .._images = images
    .._characters = characters
    .._fonts = fonts
    .._markers = markers;
}

class LottieComposition {
  static Future<LottieComposition> fromByteData(ByteData data, {String name}) {
    return fromBytes(data.buffer.asUint8List(), name: name);
  }

  static Future<LottieComposition> fromBytes(Uint8List bytes,
      {String name}) async {
    Archive archive;
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
        var found = archive.files.firstWhere(
            (f) => f.name.toLowerCase() == imagePath.toLowerCase(),
            orElse: () => null);
        if (found != null) {
          image.loadedImage = await loadImage(
              composition, image, MemoryImage(found.content as Uint8List));
        }
      }
    }

    return composition;
  }

  LottieComposition._(this.name);

  final String name;
  final _performanceTracker = PerformanceTracker();
  // This is stored as a set to avoid duplicates.
  final _warnings = <String>{};
  Map<String, List<Layer>> _precomps;
  Map<String, LottieImageAsset> _images;

  /// Map of font names to fonts */
  Map<String, Font> _fonts;
  List<Marker> _markers;
  Map<int, FontCharacter> _characters;
  Map<int, Layer> _layerMap;
  List<Layer> _layers;
  Rectangle<int> _bounds;
  double _startFrame;
  double _endFrame;
  double _frameRate;

  /// Used to determine if an animation can be drawn with hardware acceleration.
  bool hasDashPattern = false;

  /// Counts the number of mattes and masks. Before Android switched to SKIA
  /// for drawing in Oreo (API 28), using hardware acceleration with mattes and masks
  /// was only faster until you had ~4 masks after which it would actually become slower.
  int _maskAndMatteCount = 0;

  void addWarning(String warning) {
    var prefix = name != null && name.isNotEmpty ? '$name: ' : '';
    logger.warning('$prefix$warning');
    _warnings.add(warning);
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

  Layer layerModelForId(int id) {
    return _layerMap[id];
  }

  Rectangle<int> get bounds => _bounds;

  Duration get duration {
    return Duration(milliseconds: (seconds * 1000).round());
  }

  double get seconds => durationFrames / _frameRate;

  double get startFrame => _startFrame;

  double get endFrame => _endFrame;

  double get frameRate => _frameRate;

  List<Layer> get layers => _layers;

  List<Layer> /*?*/ getPrecomps(String id) {
    return _precomps[id];
  }

  Map<int, FontCharacter> get characters => _characters;

  Map<String, Font> get fonts => _fonts;

  List<Marker> get markers => _markers;

  Marker /*?*/ getMarker(String markerName) {
    for (var i = 0; i < _markers.length; i++) {
      var marker = _markers[i];
      if (marker.matchesName(markerName)) {
        return marker;
      }
    }
    return null;
  }

  bool get hasImages {
    return _images.isNotEmpty;
  }

  Map<String, LottieImageAsset> get images {
    return _images;
  }

  double get durationFrames {
    return _endFrame - _startFrame;
  }

  /// Returns a "rounded" progress value according to the frameRate
  double roundProgress(double progress, {@required FrameRate frameRate}) {
    num fps;
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
    for (var layer in _layers) {
      sb.write(layer.toStringWithPrefix('\t'));
    }
    return sb.toString();
  }
}
