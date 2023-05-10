import 'package:flutter/foundation.dart';
import 'content/shape_group.dart';

@immutable
class FontCharacter {
  static int hashFor(String character, String fontFamily, String style) {
    var result = character.hashCode;
    result = 31 * result + fontFamily.hashCode;
    result = 31 * result + style.hashCode;
    return result;
  }

  final List<ShapeGroup> shapes;
  final String character;
  final double size;
  final double width;
  final String style;
  final String fontFamily;

  const FontCharacter(
      {required this.shapes,
      required this.character,
      required this.size,
      required this.width,
      required this.style,
      required this.fontFamily});

  @override
  int get hashCode {
    return hashFor(character, fontFamily, style);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontCharacter &&
          runtimeType == other.runtimeType &&
          shapes == other.shapes &&
          character == other.character &&
          size == other.size &&
          width == other.width &&
          style == other.style &&
          fontFamily == other.fontFamily;
}
