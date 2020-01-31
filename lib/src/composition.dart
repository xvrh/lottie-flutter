import 'dart:math';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'logger.dart';
import 'lottie_image_asset.dart';
import 'model/font.dart';
import 'model/font_character.dart';
import 'model/layer/layer.dart';
import 'model/marker.dart';
import 'parser/lottie_composition_parser.dart';
import 'parser/moshi/json_reader.dart';
import 'performance_tracker.dart';

LottieComposition internalCreateComposition({@required int jsonSize}) =>
    LottieComposition._(jsonSize: jsonSize);

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
  static LottieComposition fromByteData(ByteData data) {
    return LottieCompositionParser.parse(JsonReader.fromByteData(data),
        jsonSize: data.lengthInBytes);
  }

  static LottieComposition fromBytes(Uint8List bytes) {
    return LottieCompositionParser.parse(JsonReader.fromBytes(bytes),
        jsonSize: bytes.length);
  }

  LottieComposition._({@required this.jsonSize});

  final int jsonSize;
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
    logger.warning(warning);
    _warnings.add(warning);
  }

  void incrementMatteOrMaskCount(int amount) {
    _maskAndMatteCount += amount;
  }

  /// Used to determine if an animation can be drawn with hardware acceleration.
  int get maskAndMatteCount => _maskAndMatteCount;

  List<String> get warnings => _warnings.toList();

  set performanceTrackingEnabled(bool enabled) {
    _performanceTracker.enabled = enabled;
  }

  PerformanceTracker get performanceTracker => _performanceTracker;

  Layer layerModelForId(int id) {
    return _layerMap[id];
  }

  Rectangle<int> get bounds => _bounds;

  Duration get duration {
    return Duration(milliseconds: (durationFrames / _frameRate * 1000).round());
  }

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

  @override
  String toString() {
    final sb = StringBuffer('LottieComposition:\n');
    for (var layer in _layers) {
      sb.write(layer.toStringWithPrefix('\t'));
    }
    return sb.toString();
  }
}
