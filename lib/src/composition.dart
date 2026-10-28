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

/// A function that knows how to transform a list of bytes to a `LottieComposition`
typedef LottieDecoder = Future<LottieComposition?> Function(List<int> bytes);

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

  /// The property of each slot, as JSON bytes, by slot id.
  var slots = const <String, List<int>>{};

  /// Whether a property had the id of a slot that wasn't known yet.
  bool hasUnresolvedSlotIds = false;

  static CompositionParameters forComposition(LottieComposition composition) =>
      composition._parameters;
}

class LottieComposition {
  static LottieComposition parseJsonBytes(List<int> bytes) {
    var composition = _parse(bytes);
    var parameters = composition._parameters;
    if (parameters.hasUnresolvedSlotIds && parameters.slots.isNotEmpty) {
      // The slots come after properties that use them in the file: parse it
      // again with the slots known from the start.
      composition = _parse(bytes, slots: parameters.slots);
    }
    return composition;
  }

  static LottieComposition _parse(
    List<int> bytes, {
    Map<String, List<int>> slots = const {},
  }) {
    var composition = LottieComposition._();
    composition._parameters.slots = slots;
    return LottieCompositionParser.parse(
      composition,
      JsonReader.fromBytes(bytes),
    );
  }

  static Future<LottieComposition> fromByteData(
    ByteData data, {
    LottieDecoder? decoder,
  }) {
    return fromBytes(data.buffer.asUint8List(), decoder: decoder);
  }

  static Future<LottieComposition> fromBytes(
    List<int> bytes, {
    LottieDecoder? decoder,
  }) async {
    decoder ??= decodeZip;

    var compositionFuture = await decoder(bytes);
    if (compositionFuture != null) {
      return compositionFuture;
    }
    return parseJsonBytes(bytes);
  }

  static Future<LottieComposition?> decodeZip(
    List<int> bytes, {
    LottieImageProviderFactory? imageProviderFactory,
    ArchiveFile? Function(List<ArchiveFile>)? filePicker,
  }) async {
    if (bytes[0] == 0x50 && bytes[1] == 0x4B) {
      var archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? jsonFile;
      if (filePicker != null) {
        jsonFile = filePicker(archive.files);
      }
      jsonFile ??= archive.files.firstWhereOrNull(
        (e) => e.name.startsWith('animations/') && e.name.endsWith('.json'),
      );
      jsonFile ??= archive.files.firstWhere(
        (e) =>
            e.name.endsWith('.json') && p.basename(e.name) != 'manifest.json',
      );

      var composition = parseJsonBytes(jsonFile.content);

      await loadImages(composition.images.values, (image) async {
        var imagePath = p.posix.join(image.dirName, image.fileName);
        var found = archive.files.firstWhereOrNull(
          (f) =>
              _normalizeArchivePath(f.name) == _normalizeArchivePath(imagePath),
        );

        ImageProvider? provider;
        if (imageProviderFactory != null) {
          provider = imageProviderFactory(image);
        }

        if (provider != null) {
          image.loadedImage = await loadImage(composition, image, provider);
        }

        if (found != null) {
          image.loadedImage ??= await loadImage(
            composition,
            image,
            MemoryImage(found.content),
          );
        }
      });

      var fontFiles = {
        for (var file in archive.files)
          if (_fontExtensions.contains(p.extension(file.name).toLowerCase()))
            p.basenameWithoutExtension(file.name).toLowerCase(): file,
      };
      for (var font in composition.fonts.values) {
        var file =
            fontFiles[font.name.toLowerCase()] ??
            fontFiles[font.family.toLowerCase()];
        if (file != null) {
          composition._fontsToLoad.add(FontToLoad(file.content, font));
        }
      }
      return composition;
    }
    return null;
  }

  static const _fontExtensions = {'.ttf', '.otf'};

  static String _normalizeArchivePath(String path) {
    var normalized = p.posix.normalize(path).toLowerCase();
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }

  static Future<LottieComposition?> decodeGZip(List<int> bytes) async {
    if (bytes[0] == 31 && bytes[1] == 139) {
      var decodedBytes = GZipDecoder().decodeBytes(bytes);
      return LottieComposition.parseJsonBytes(decodedBytes);
    }
    return null;
  }

  LottieComposition._();

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

  final _fontsToLoad = <FontToLoad>[];

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

  /// Number of frames in the animation
  double get durationFrames => endFrame - startFrame;

  /// Returns a "rounded" progress value according to the frameRate
  double roundProgress(double progress, {required FrameRate frameRate}) {
    var fps = frameRate.resolveFps(this.frameRate);
    if (fps == null) {
      return progress;
    }

    var noOffsetDurationFrames = durationFrames + 0.01;
    var totalFrameCount = (noOffsetDurationFrames / this.frameRate) * fps;
    // The epsilon absorbs the float error of adding back the 0.01 offset
    // (e.g. 69.99 - 10 + 0.01 == 59.99999999999999).
    var frameIndex = (totalFrameCount * progress + 1e-6).toInt();
    // Progress is relative to durationFrames, which excludes the 0.01 offset.
    var roundedProgress = min(frameIndex / (seconds * fps), 1.0);
    assert(
      roundedProgress >= 0 && roundedProgress <= 1,
      'Progress is $roundedProgress',
    );
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

class FontToLoad {
  final Uint8List bytes;
  final Font font;

  FontToLoad(this.bytes, this.font);

  static List<FontToLoad>? getAndClear(LottieComposition composition) {
    if (composition._fontsToLoad.isNotEmpty) {
      var fonts = composition._fontsToLoad.toList();
      composition._fontsToLoad.clear();
      return fonts;
    }
    return null;
  }
}
