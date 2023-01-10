import 'package:flutter/widgets.dart';

extension CharactersExtension on Characters {
  Characters trimTrailing(Characters pattern) {
    if (pattern.isEmpty) return this;

    var i = length;
    while (i >= pattern.length && getRange(i - pattern.length, i) == pattern) {
      i -= pattern.length;
    }
    return getRange(0, i);
  }

  Characters trimLeading(Characters pattern) {
    if (pattern.isEmpty) return this;
    var i = 0;
    while (i <= length - pattern.length &&
        getRange(i, i + pattern.length) == pattern) {
      i += pattern.length;
    }
    return getRange(i);
  }

  Characters trim(Characters pattern) {
    return trimLeading(pattern).trimTrailing(pattern);
  }
}
