import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart' show RenderBox;
import '../lottie.dart';
import 'render_cache/store_drawing.dart';
import 'render_cache/store_raster.dart';
import 'utils.dart';

abstract class RenderCache {
  /// The frames stored in the cache are fully rasterized. This is the most efficient
  /// to render but will use the most memory.
  /// This should only be used for very short and very small animations (final size on the screen).
  static const raster = RenderCacheRaster(maxMemory: 50000000);

  /// The frames are stored as [dart:ui.Picture] in the cache.
  /// It will will spare the CPU work for each frame. The GPU work will be the same as without cache.
  static const drawingCommands = RenderCacheDrawing();

  AnimationCache acquire(Object user);

  void release(Object user);
}

abstract class AnimationCache {
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
  });
}

var _ = "";
//TODO(xha):
// - Strategy acquire/release shared accross cache
// - Strategy compute size shared across cache
// - Strategy immediate clear cache when release last handle can be overriden (sometime, we may want to do it manually).
// -

// Test strategy:
// - Create an app where we can toggle the "background debug"
//   Lot of lines with Disable | DrawingCommands | Raster
// - Test all BoxFit & Size
