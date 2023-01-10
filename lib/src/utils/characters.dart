

import 'package:flutter/widgets.dart';

extension CharactersExtension on Characters {
  Characters trimTrailing(String pattern) {
    if (pattern.isEmpty) return this;

    var patternChars = pattern.characters;
    if (length < patternChars.length) return this;

    var i = length;
    while (i > 0 && getRange(i - pattern.characters.length, i) == patternChars) {
      i -= pattern.length;
    }
    return getRange(0, i);
  }
}