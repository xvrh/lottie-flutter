import 'dart:ui';
import 'package:flutter/foundation.dart';

enum Justification { leftAlign, rightAlign, center }

@immutable
class DocumentData {
  final String text;
  final String? fontName;
  final double size;
  final Justification justification;
  final int tracking;

  /// Extra space in between lines. */
  final double lineHeight;
  final double baselineShift;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final bool strokeOverFill;
  final Offset? boxPosition;
  final Offset? boxSize;

  const DocumentData({
    required this.text,
    this.fontName,
    required this.size,
    required this.justification,
    required this.tracking,
    required this.lineHeight,
    required this.baselineShift,
    required this.color,
    required this.strokeColor,
    required this.strokeWidth,
    required this.strokeOverFill,
    required this.boxPosition,
    required this.boxSize,
  });

  @override
  int get hashCode {
    return Object.hash(
      text,
      fontName,
      size,
      justification.index,
      tracking,
      lineHeight,
      baselineShift,
      color,
      strokeColor,
      strokeWidth,
      strokeOverFill,
      boxPosition,
      boxSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentData &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          fontName == other.fontName &&
          size == other.size &&
          justification == other.justification &&
          tracking == other.tracking &&
          lineHeight == other.lineHeight &&
          baselineShift == other.baselineShift &&
          color == other.color &&
          strokeColor == other.strokeColor &&
          strokeWidth == other.strokeWidth &&
          strokeOverFill == other.strokeOverFill &&
          boxPosition == other.boxPosition &&
          boxSize == other.boxSize;
}
