import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import '../lottie.dart';
import 'utils.dart';

enum RenderCacheMode {
  /// The frames stored in the cache are fully rasterized. This is the most efficient
  /// to render but will use the most memory.
  /// This should only be used for very short and small animation (final size on the screen).
  raster,

  /// The frames are stored as [dart:ui.Picture] in the cache.
  /// It will will spare the CPU work for each frame. The GPU work will be the same as without cache.
  drawingCommands,

  /// The frame is not stored in the cache.
  disabled,
}

final globalRenderCache = RenderCache();

class RenderCache {
  final _onUpdateController = StreamController<void>.broadcast();
  final entries = <CacheKey, RenderCacheEntry>{};
  final handles = <Object, RenderCacheHandle>{};

  /// The maximum memory this cache will use (default 50MB)
  /// It should refuse to create new images if the size is exceeded.
  static const int defaultMaxMemory = 50000000;

  int maxMemory = defaultMaxMemory;

  bool enableDebugBackground = false;

  Stream<void> get onUpdate => _onUpdateController.stream;

  int get handleCount => handles.length;

  int get entryCount => entries.length;

  int get imageCount =>
      entries.values.map((e) => e.images.length).fold<int>(0, (a, b) => a + b);

  int get totalMemory => entries.values
      .expand((e) => e.images.values)
      .fold(0, (a, b) => a + b.width * b.height);

  bool canUseMemory(int newMemory) {
    return totalMemory + newMemory <= maxMemory;
  }

  void clear() {
    for (var entry in entries.values) {
      entry._clear();
    }
    _notifyUpdate();
  }

  void _clearUnused() {
    for (var entry in entries.entries.toList()) {
      var key = entry.key;
      var cache = entry.value;

      if (cache.handles.isEmpty) {
        cache.dispose();
        var found = entries.remove(key);
        assert(found == cache);
      }
    }
  }

  void _notifyUpdate() {
    _onUpdateController.add(null);
  }

  RenderCacheHandle acquire(Object user) {
    return handles[user] ??= RenderCacheHandle(this);
  }

  void release(Object user) {
    var handle = handles.remove(user);
    if (handle?._currentEntry case var currentEntry?) {
      currentEntry.handles.remove(handle);
      _clearUnused();
      _notifyUpdate();
    }
  }

  void dispose() {
    _onUpdateController.close();
  }
}

class RenderCacheHandle {
  final RenderCache _cache;
  RenderCacheEntry? _currentEntry;

  RenderCacheHandle(this._cache);

  RenderCacheEntry withKey(CacheKey key) {
    if (_currentEntry case var currentEntry? when currentEntry.key != key) {
      _currentEntry = null;
      currentEntry.handles.remove(this);
      _cache._clearUnused();
    }
    var entry = _cache.entries[key] ??= RenderCacheEntry(_cache, key);
    entry.handles.add(this);
    _currentEntry = entry;
    _cache._notifyUpdate();
    return entry;
  }
}

var _debugId = 0;

class RenderCacheEntry {
  final RenderCache _cache;
  final CacheKey key;
  final handles = <RenderCacheHandle>{};
  final pictures = <double, Picture>{};
  final images = <double, Image>{};
  bool _isDisposed = false;
  final _id = _debugId++;

  RenderCacheEntry(this._cache, this.key);

  ui.Picture _record(void Function(Canvas) draw) {
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    if (_cache.enableDebugBackground) {
      _drawDebugBackground(canvas, key.size);
    }
    draw(canvas);
    return recorder.endRecording();
  }

  ui.Picture? pictureForProgress(double progress, void Function(Canvas) draw) {
    assert(!_isDisposed);

    var existing = pictures[progress];
    if (existing != null) {
      return existing;
    }

    var picture = _record( draw);
    pictures[progress] = picture;
    _cache._notifyUpdate();
    return picture;
  }

  ui.Image? imageForProgress(double progress, void Function(Canvas) draw) {
    assert(!_isDisposed);

    var existing = images[progress];
    if (existing != null) {
      return existing;
    }

    var size = key.size;
    var newImageSize = size.width.round() * size.height.round();
    if (!_cache.canUseMemory(newImageSize)) {
      return null;
    }

    var picture = _record(draw);
    var image = picture.toImageSync(size.width.round(), size.height.round());
    images[progress] = image;
    picture.dispose();
    _cache._notifyUpdate();
    return image;
  }

  void _drawDebugBackground(Canvas canvas, Size size) {
    var debugColors = [
      Colors.yellow,
      Colors.orange,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.amber
    ];
    var color = debugColors[_id % debugColors.length];
    canvas.drawRect(
        Offset.zero & size, Paint()..color = color.withOpacity(0.2));
  }

  void _clear() {
    for (var image in images.values) {
      image.dispose();
    }
    images.clear();
  }

  void dispose() {
    _isDisposed = true;
    _clear();
  }
}

@immutable
class CacheKey {
  final LottieComposition composition;
  final Size size;
  final List<Object?> config;
  final int delegates;

  CacheKey({
    required this.composition,
    required this.size,
    required this.config,
    required this.delegates,
  }) : assert(size.width == size.width.toInt() &&
            size.height == size.height.toInt());

  @override
  int get hashCode =>
      Object.hash(composition, size, Object.hashAll(config), delegates);

  @override
  bool operator ==(other) =>
      other is CacheKey &&
      other.composition == composition &&
      other.size == size &&
      const ListEquality<Object?>().equals(other.config, config) &&
      other.delegates == delegates;

  @override
  String toString() =>
      'CacheKey(${composition.hashCode}, $size, $config, $delegates)';
}
