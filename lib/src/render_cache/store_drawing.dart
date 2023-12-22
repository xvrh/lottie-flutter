import 'dart:ui';
import 'package:flutter/rendering.dart';
import '../lottie_drawable.dart';
import '../render_cache.dart';
import 'key.dart';
import 'store.dart';

final _stores = Expando<DrawingStore>();

class RenderCacheDrawing implements RenderCache {
  const RenderCacheDrawing();

  @override
  AnimationCache acquire(Object user) {
    var handle = store.acquire(user);
    return DrawingAnimationCache(handle);
  }

  @override
  void release(Object user) {
    store.release(user);
  }

  DrawingStore get store => _stores[this] ??= DrawingStore();
}

class DrawingAnimationCache extends AnimationCache {
  final Handle<DrawingEntry, CacheKey> handle;

  DrawingAnimationCache(this.handle);

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
    var key = CacheKey(
        composition: drawable.composition,
        size: Size.zero,
        config: drawable.configHash(),
        delegates: drawable.delegatesHash());
    var entry = handle.withKey(key);

    return entry.draw(
      drawable,
      progress,
      canvas,
      destinationPosition: destinationPosition,
      destinationRect: destinationRect,
      sourceRect: sourceRect,
      sourceSize: sourceSize,
    );
  }
}

class DrawingStore extends Store<DrawingEntry, CacheKey> {
  @override
  DrawingEntry createEntry(CacheKey key) {
    return DrawingEntry(this, key);
  }
}

base class DrawingEntry extends CacheEntry<CacheKey> {
  final DrawingStore store;
  final pictures = <double, Picture>{};

  DrawingEntry(this.store, super.key);

  Picture _record(void Function(Canvas) draw) {
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    draw(canvas);
    return recorder.endRecording();
  }

  Picture? _pictureForProgress(double progress, void Function(Canvas) draw) {
    var existing = pictures[progress];
    if (existing != null) {
      return existing;
    }

    var picture = _record(draw);
    pictures[progress] = picture;
    return picture;
  }

  final _matrix = Matrix4.identity();

  bool draw(
    LottieDrawable drawable,
    double progress,
    Canvas canvas, {
    required Offset destinationPosition,
    required Rect destinationRect,
    required Rect sourceRect,
    required Size sourceSize,
  }) {
    var cachedImage = _pictureForProgress(progress, (cacheCanvas) {
      drawable.compositionLayer.draw(cacheCanvas, _matrix, parentAlpha: 255);
    });
    if (cachedImage != null) {
      var destinationSize = destinationRect.size;

      canvas.save();
      canvas.translate(destinationRect.left, destinationRect.top);
      canvas.scale(destinationSize.width / sourceRect.width,
          destinationSize.height / sourceRect.height);
      canvas.drawPicture(cachedImage);
      canvas.restore();

      return true;
    }

    return false;
  }

  @override
  void dispose() {
    for (var picture in pictures.values) {
      picture.dispose();
    }
    pictures.clear();
  }
}
