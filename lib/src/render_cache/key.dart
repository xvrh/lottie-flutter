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
