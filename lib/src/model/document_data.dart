import 'dart:ui';

enum Justification { leftAlign, rightAlign, center }

class DocumentData {
  final String text;
  final String? fontName;
  final double size;
  final Justification justification;
  final int tracking;
  final double lineHeight;
  final double baselineShift;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final bool strokeOverFill;

  DocumentData({
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
  });

  @override
  int get hashCode {
    return hashValues(
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
        strokeOverFill);
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
          strokeOverFill == other.strokeOverFill;
}
