import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../composition.dart';
import '../utils.dart';

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
  }) : assert(
         size.width == size.width.toInt() && size.height == size.height.toInt(),
       );

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

/// A [CacheKey] for the raster cache, where frames are rasterized and cropped
/// to [sourceRect] ahead of time. Unlike the drawing-commands cache (whose
/// cached [Picture] is recorded in full composition space and cropped fresh
/// on every draw), the same [composition]/[size] with a different
/// [sourceRect] (i.e. a different `fit`/`alignment`) must not share a cached
/// image.
@immutable
class RasterCacheKey extends CacheKey {
  final Rect sourceRect;

  RasterCacheKey({
    required super.composition,
    required super.size,
    required this.sourceRect,
    required super.config,
    required super.delegates,
  });

  @override
  int get hashCode => Object.hash(super.hashCode, sourceRect);

  @override
  bool operator ==(other) =>
      other is RasterCacheKey &&
      super == other &&
      other.sourceRect == sourceRect;

  @override
  String toString() => '${super.toString()}, sourceRect: $sourceRect';
}
