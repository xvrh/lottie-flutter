library noise;

import 'charcode.dart' as char;
import 'lexer.dart' show isEOL, isWhitespace;

class Offsets {
  int start;
  int end;
  int line;
  Offsets(this.start, this.end, this.line);
}

/// Detects noise surrounding the source code and adjusts initial and ending offsets to ignore the noise.
///
/// The following things are considered noise:
/// - Hash bang: e.g. "#!/usr/bin/env node"
/// - HTML comment: <!--, -->
/// - HTML cdata tag: <![CDATA[, ]]>
Offsets trimNoise(String text, Offsets offsets) {
  int index = offsets.start;
  int end = offsets.end;
  int currentLine = offsets.line;
  bool lookahead(String str) {
    if (index + str.length > end) return false;
    for (int i = 0; i < str.length; i++) {
      if (text.codeUnitAt(index + i) != str.codeUnitAt(i)) return false;
    }
    return true;
  }

  bool lookback(String str) {
    if (str.length > end) return false;
    for (int i = 0; i < str.length; i++) {
      if (text.codeUnitAt(end - str.length + i) != str.codeUnitAt(i))
        return false;
    }
    return true;
  }

  int next() {
    ++index;
    return index == end ? char.NULL : text.codeUnitAt(index);
  }

  // Skip line with #!
  if (lookahead('#!')) {
    index += 2;
    while (index < end && !isEOL(text.codeUnitAt(index))) {
      ++index;
    }
  }

  // Skip whitespace until potential HTML comment marker
  loop:
  while (true) {
    int x = text.codeUnitAt(index);
    switch (x) {
      case char.LF:
      case char.LS:
      case char.PS:
        currentLine += 1;
        x = next();
        break;
      case char.CR:
        currentLine += 1;
        x = next();
        if (x == char.LF) {
          x = next();
        }
        break;
      default:
        if (isWhitespace(x)) {
          x = next();
        } else {
          break loop;
        }
    }
  }

  // Skip <!-- and <![CDATA[
  if (lookahead('<!--')) {
    index += '<!--'.length;
  } else if (lookahead('<![CDATA[')) {
    index += '<![CDATA['.length;
  }

  // Skip suffix whitespace (this is simpler than above since we do not need to update the line counter)
  while (end > 0) {
    int x = text.codeUnitAt(end - 1);
    if (!isWhitespace(x) && !isEOL(x)) break;
    --end;
  }

  // Check for trailing --> or ]]>
  if (lookback('-->')) {
    end -= '-->'.length;
  } else if (lookback(']]>')) {
    end -= ']]>'.length;
  }

  return new Offsets(index, end, currentLine);
}
