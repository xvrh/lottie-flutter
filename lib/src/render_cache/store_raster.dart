import 'dart:ui';
import 'package:flutter/rendering.dart';
import '../lottie_drawable.dart';
import '../render_cache.dart';
import 'key.dart';
import 'store.dart';

final _stores = Expando<RasterStore>();

class RenderCacheRaster implements RenderCache {
  final int maxMemory;

  const RenderCacheRaster({required this.maxMemory});

  @override
  AnimationCache acquire(Object user) {
    var handle = store.acquire(user);
    return RasterAnimationCache(handle);
  }

  @override
  void release(Object user) {
    store.release(user);
  }

  RasterStore get store => _stores[this] ??= RasterStore(maxMemory);
}

class RasterAnimationCache extends AnimationCache {
  final Handle<RasterEntry, CacheKey> handle;

  RasterAnimationCache(this.handle);

  @override
  bool draw(
    LottieDrawable drawable,
    double progress,
    Canvas canvas, {
    required Offset destinationPosition,
    required Rect destinationRect,
    required Rect sourceRect,
    required Size sourceSize,
    required RenderBox renderBox,
    required double devicePixelRatio,
  }) {
    var rect = Rect.fromPoints(renderBox.localToGlobal(destinationPosition),
        renderBox.localToGlobal(destinationRect.bottomRight));
    var cacheImageSize = Size(
        (rect.size.width * devicePixelRatio).roundToDouble(),
        (rect.size.height * devicePixelRatio).roundToDouble());

    var key = CacheKey(
        composition: drawable.composition,
        size: cacheImageSize,
        config: drawable.configHash(),
        delegates: drawable.delegatesHash());
    var entry = handle.withKey(key);

    return entry.draw(
      drawable,
      progress,
      canvas,
      destinationPosition: destinationPosition,
      destinationRect: destinationRect,
      sourceSize: sourceSize,
      sourceRect: sourceRect,
    );
  }
}

class RasterStore extends Store<RasterEntry, CacheKey> {
  final int maxMemory;

  RasterStore(this.maxMemory);

  int get totalMemory => entries.values.fold(0, (a, b) => a + b.currentMemory);

  int get imageCount => entries.values.expand((e) => e.images.values).length;

  void clear() {
    for (var entry in entries.values) {
      entry.clear();
    }
  }

  @override
  RasterEntry createEntry(CacheKey key) {
    return RasterEntry(this, key);
  }

  bool canUseMemory(int newMemory) {
    return totalMemory + newMemory <= maxMemory;
  }
}

base class RasterEntry extends CacheEntry<CacheKey> {
  final RasterStore store;
  final images = <double, Image>{};
  int currentMemory = 0;

  RasterEntry(this.store, super.key);

  Picture _record(void Function(Canvas) draw) {
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    draw(canvas);
    return recorder.endRecording();
  }

  Image? imageForProgress(double progress, void Function(Canvas) draw) {
    var existing = images[progress];
    if (existing != null) {
      return existing;
    }

    var size = key.size;
    var newImageSize = size.width.round() * size.height.round();
    if (!store.canUseMemory(newImageSize)) {
      return null;
    }

    var picture = _record(draw);
    var image = picture.toImageSync(size.width.round(), size.height.round());
    picture.dispose();
    images[progress] = image;
    currentMemory += size.width.round() * size.height.round();
    return image;
  }

  final _normalPaint = Paint();
  final _matrix = Matrix4.identity();

  bool draw(
    LottieDrawable drawable,
    double progress,
    Canvas canvas, {
    required Offset destinationPosition,
    required Rect destinationRect,
    required Size sourceSize,
    required Rect sourceRect,
  }) {
    var cacheImageSize = key.size;

    var cachedImage = imageForProgress(progress, (cacheCanvas) {
      _matrix.setIdentity();
      _matrix.scale(cacheImageSize.width / sourceSize.width,
          cacheImageSize.height / sourceSize.height);
      drawable.compositionLayer.draw(cacheCanvas, _matrix, parentAlpha: 255);
    });
    if (cachedImage != null) {
      canvas.drawImageRect(cachedImage, Offset.zero & cacheImageSize,
          destinationRect, _normalPaint);
      return true;
    }

    return false;
  }

  void clear() {
    for (var image in images.values) {
      image.dispose();
    }
    images.clear();
    currentMemory = 0;
  }

  @override
  void dispose() {
    clear();
  }
}
