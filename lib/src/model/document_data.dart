import 'dart:ui';

enum Justification { LEFT_ALIGN, RIGHT_ALIGN, CENTER }

class DocumentData {
  final String text;
  final String fontName;
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
    this.text,
    this.fontName,
    this.size,
    this.justification,
    this.tracking,
    this.lineHeight,
    this.baselineShift,
    this.color,
    this.strokeColor,
    this.strokeWidth,
    this.strokeOverFill,
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
}
