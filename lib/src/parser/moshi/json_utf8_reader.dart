import 'dart:convert';
import 'dart:core';
import 'buffer.dart';
import 'charcode.dart';
import 'json_reader.dart';
import 'json_scope.dart';

class JsonUtf8Reader extends JsonReader {
  static const int longMinValue = -9007199254740991;

  static const minIncompleteInteger = longMinValue ~/ 10;

  static final List<int> singleQuoteOrSlash = utf8.encode(r"'\");
  static final List<int> doubleQuoteOrSlash = utf8.encode(r'"\');
  static final List<int> unquotedStringTerminals =
      utf8.encode('{}[]:, \n\t\r\f/\\;#=');
  static final List<int> lineFeedOrCarriageReturn = utf8.encode('\n\r');
  static final List<int> closingBlockComment = utf8.encode('*/');

  static const int peekedNone = 0;
  static const int peekedBeginObject = 1;
  static const int peekedEndObject = 2;
  static const int peekedBeginArray = 3;
  static const int peekedEndArray = 4;
  static const int peekedTrue = 5;
  static const int peekedFalse = 6;
  static const int peekedNull = 7;
  static const int peekedSingleQuote = 8;
  static const int peekedDoubleQuote = 9;
  static const int peekedUnquoted = 10;

  /// When this is returned, the string value is stored in peekedString. */
  static const int peekedBuffered = 11;
  static const int peekedSingleQuotedName = 12;
  static const int peekedDoubleQuotedName = 13;
  static const int peekedUnquotedName = 14;
  static const int peekedBufferedName = 15;

  /// When this is returned, the integer value is stored in peekedLong. */
  static const int peekedLong = 16;
  static const int peekedNumber = 17;
  static const int peekedEof = 18;

  // State machine when parsing numbers
  static const int numberCharNone = 0;
  static const int numberCharSign = 1;
  static const int numberCharDigit = 2;
  static const int numberCharDecimal = 3;
  static const int numberCharFractionDigit = 4;
  static const int numberCharExpE = 5;
  static const int numberCharExpSign = 6;
  static const int numberCharExpDigit = 7;

  /// The input JSON. */
  final Buffer buffer;

  int _peeked = peekedNone;

  /// A peeked value that was composed entirely of digits with an optional
  /// leading dash. Positive values may not have a leading 0.
  late int _peekedLong;

  /// The number of characters in a peeked number literal.
  late int _peekedNumberLength;

  /// A peeked string that should be parsed on the next double, long or string.
  /// This is populated before a numeric value is parsed and used if that parsing
  /// fails.
  String? _peekedString;

  JsonUtf8Reader(this.buffer) {
    pushScope(JsonScope.emptyDocument);
  }

  @override
  void beginArray() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    if (p == peekedBeginArray) {
      pushScope(JsonScope.emptyArray);
      pathIndices[stackSize - 1] = 0;
      _peeked = peekedNone;
    } else {
      throw JsonDataException(
          'Expected BEGIN_ARRAY but was ${peek()} at path ${getPath()}');
    }
  }

  @override
  void endArray() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    if (p == peekedEndArray) {
      stackSize--;
      pathIndices[stackSize - 1]++;
      _peeked = peekedNone;
    } else {
      throw JsonDataException(
          'Expected END_ARRAY but was ${peek()} at path ${getPath()}');
    }
  }

  @override
  void beginObject() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    if (p == peekedBeginObject) {
      pushScope(JsonScope.emptyObject);
      _peeked = peekedNone;
    } else {
      throw JsonDataException(
          'Expected BEGIN_OBJECT but was ${peek()} at path ${getPath()}');
    }
  }

  @override
  void endObject() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    if (p == peekedEndObject) {
      stackSize--;
      pathNames[stackSize] =
          null; // Free the last path name so that it can be garbage collected!
      pathIndices[stackSize - 1]++;
      _peeked = peekedNone;
    } else {
      throw JsonDataException(
          'Expected END_OBJECT but was ${peek()} at path ${getPath()}');
    }
  }

  @override
  bool hasNext() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    return p != peekedEndObject && p != peekedEndArray && p != peekedEof;
  }

  @override
  Token peek() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }

    switch (p) {
      case peekedBeginObject:
        return Token.beginObject;
      case peekedEndObject:
        return Token.endObject;
      case peekedBeginArray:
        return Token.beginArray;
      case peekedEndArray:
        return Token.endArray;
      case peekedSingleQuotedName:
      case peekedDoubleQuotedName:
      case peekedUnquotedName:
      case peekedBufferedName:
        return Token.name;
      case peekedTrue:
      case peekedFalse:
        return Token.boolean;
      case peekedNull:
        return Token.nullToken;
      case peekedSingleQuote:
      case peekedDoubleQuote:
      case peekedUnquoted:
      case peekedBuffered:
        return Token.string;
      case peekedLong:
      case peekedNumber:
        return Token.number;
      case peekedEof:
        return Token.endDocument;
      default:
        throw AssertionError();
    }
  }

  int _doPeek() {
    var peekStack = scopes[stackSize - 1];
    if (peekStack == JsonScope.emptyArray) {
      scopes[stackSize - 1] = JsonScope.nonEmptyArray;
    } else if (peekStack == JsonScope.nonEmptyArray) {
      // Look for a comma before the next element.
      var c = _nextNonWhitespace(true);
      buffer.readByte(); // consume ']' or ','.
      switch (c) {
        case $closeBracket:
          return _peeked = peekedEndArray;
        case $semicolon:
          _checkLenient();
        case $comma:
          break;
        default:
          throw syntaxError('Unterminated array');
      }
    } else if (peekStack == JsonScope.emptyObject ||
        peekStack == JsonScope.nonEmptyObject) {
      scopes[stackSize - 1] = JsonScope.danglingName;
      // Look for a comma before the next element.
      if (peekStack == JsonScope.nonEmptyObject) {
        var c = _nextNonWhitespace(true);
        buffer.readByte(); // Consume '}' or ','.
        switch (c) {
          case $closeBrace:
            return _peeked = peekedEndObject;
          case $semicolon:
            _checkLenient(); // fall-through
          case $comma:
            break;
          default:
            throw syntaxError('Unterminated object');
        }
      }
      var c = _nextNonWhitespace(true);
      switch (c) {
        case $doubleQuote:
          buffer.readByte(); // consume the '\"'.
          return _peeked = peekedDoubleQuotedName;
        case $singleQuote:
          buffer.readByte(); // consume the '\''.
          _checkLenient();
          return _peeked = peekedSingleQuotedName;
        case $closeBrace:
          if (peekStack != JsonScope.nonEmptyObject) {
            buffer.readByte(); // consume the '}'.
            return _peeked = peekedEndObject;
          }
          throw syntaxError('Expected name');

        default:
          _checkLenient();
          if (isLiteral(c)) {
            return _peeked = peekedUnquotedName;
          } else {
            throw syntaxError('Expected name');
          }
      }
    } else if (peekStack == JsonScope.danglingName) {
      scopes[stackSize - 1] = JsonScope.nonEmptyObject;
      // Look for a colon before the value.
      var c = _nextNonWhitespace(true);
      buffer.readByte(); // Consume ':'.
      switch (c) {
        case $colon:
          break;
        case $equal:
          _checkLenient();
          if (buffer.request(1) && buffer.getByte(0) == $greaterThan) {
            buffer.readByte(); // Consume '>'.
          }
        default:
          throw syntaxError("Expected ':'");
      }
    } else if (peekStack == JsonScope.emptyDocument) {
      scopes[stackSize - 1] = JsonScope.nonEmptyDocument;
    } else if (peekStack == JsonScope.nonEmptyDocument) {
      var c = _nextNonWhitespace(false);
      if (c == -1) {
        return _peeked = peekedEof;
      } else {
        _checkLenient();
      }
    } else if (peekStack == JsonScope.closed) {
      throw StateError('JsonReader is closed');
    }

    var c = _nextNonWhitespace(true);
    switch (c) {
      case $closeBracket:
      // fall-through to handle ",]"
      case $semicolon:
      case $comma:
        if (c == $closeBracket) {
          if (peekStack == JsonScope.emptyArray) {
            buffer.readByte(); // Consume ']'.
            return _peeked = peekedEndArray;
          }
        }
        // In lenient mode, a 0-length literal in an array means 'null'.
        if (peekStack == JsonScope.emptyArray ||
            peekStack == JsonScope.nonEmptyArray) {
          _checkLenient();
          return _peeked = peekedNull;
        } else {
          throw syntaxError('Unexpected value');
        }
      case $singleQuote:
        _checkLenient();
        buffer.readByte(); // Consume '\''.
        return _peeked = peekedSingleQuote;
      case $doubleQuote:
        buffer.readByte(); // Consume '\"'.
        return _peeked = peekedDoubleQuote;
      case $openBracket:
        buffer.readByte(); // Consume '['.
        return _peeked = peekedBeginArray;
      case $openBrace:
        buffer.readByte(); // Consume '{'.
        return _peeked = peekedBeginObject;
      default:
    }

    var result = peekKeyword();
    if (result != peekedNone) {
      return result;
    }

    result = peekNumber();
    if (result != peekedNone) {
      return result;
    }

    if (!isLiteral(buffer.getByte(0))) {
      throw syntaxError('Expected value');
    }

    _checkLenient();
    return _peeked = peekedUnquoted;
  }

  int peekKeyword() {
    // Figure out which keyword we're matching against by its first character.
    var c = buffer.getByte(0);
    String keyword;
    String keywordUpper;
    int peeking;
    if (c == $t || c == $T) {
      keyword = 'true';
      keywordUpper = 'TRUE';
      peeking = peekedTrue;
    } else if (c == $f || c == $F) {
      keyword = 'false';
      keywordUpper = 'FALSE';
      peeking = peekedFalse;
    } else if (c == $n || c == $N) {
      keyword = 'null';
      keywordUpper = 'NULL';
      peeking = peekedNull;
    } else {
      return peekedNone;
    }

    // Confirm that chars [1..length) match the keyword.
    var length = keyword.length;
    for (var i = 1; i < length; i++) {
      if (!buffer.request(i + 1)) {
        return peekedNone;
      }
      c = buffer.getByte(i);
      if (c != keyword[i].codeUnitAt(0) && c != keywordUpper[i].codeUnitAt(0)) {
        return peekedNone;
      }
    }

    if (buffer.request(length + 1) && isLiteral(buffer.getByte(length))) {
      return peekedNone; // Don't match trues, falsey or nullsoft!
    }

    // We've found the keyword followed either by EOF or by a non-literal character.
    buffer.skip(length);
    return _peeked = peeking;
  }

  int peekNumber() {
    var value = 0; // Negative to accommodate Long.MIN_VALUE more easily.
    var negative = false;
    var fitsInLong = true;
    var last = numberCharNone;

    var i = 0;

    for (; true; i++) {
      if (!buffer.request(i + 1)) {
        break;
      }

      var c = buffer.getByte(i);
      if (c == $dash) {
        if (last == numberCharNone) {
          negative = true;
          last = numberCharSign;
          continue;
        } else if (last == numberCharExpE) {
          last = numberCharExpSign;
          continue;
        }
        return peekedNone;
      } else if (c == $plus) {
        if (last == numberCharExpE) {
          last = numberCharExpSign;
          continue;
        }
        return peekedNone;
      } else if (c == $e || c == $E) {
        if (last == numberCharDigit || last == numberCharFractionDigit) {
          last = numberCharExpE;
          continue;
        }
        return peekedNone;
      } else if (c == $dot) {
        if (last == numberCharDigit) {
          last = numberCharDecimal;
          continue;
        }
        return peekedNone;
      } else {
        if (c < $0 || c > $9) {
          if (!isLiteral(c)) {
            break;
          }
          return peekedNone;
        }
        if (last == numberCharSign || last == numberCharNone) {
          value = -(c - $0);
          last = numberCharDigit;
        } else if (last == numberCharDigit) {
          if (value == 0) {
            return peekedNone; // Leading '0' prefix is not allowed (since it could be octal).
          }
          var newValue = value * 10 - (c - $0);
          fitsInLong &= value > minIncompleteInteger ||
              (value == minIncompleteInteger && newValue < value);
          value = newValue;
        } else if (last == numberCharDecimal) {
          last = numberCharFractionDigit;
        } else if (last == numberCharExpE || last == numberCharExpSign) {
          last = numberCharExpDigit;
        }
      }
    }

    // We've read a complete number. Decide if it's a PEEKED_LONG or a PEEKED_NUMBER.
    if (last == numberCharDigit &&
        fitsInLong &&
        (value != longMinValue || negative) &&
        (value != 0 || !negative)) {
      _peekedLong = negative ? value : -value;
      buffer.skip(i);
      return _peeked = peekedLong;
    } else if (last == numberCharDigit ||
        last == numberCharFractionDigit ||
        last == numberCharExpDigit) {
      _peekedNumberLength = i;
      return _peeked = peekedNumber;
    } else {
      return peekedNone;
    }
  }

  bool isLiteral(int c) {
    switch (c) {
      case $slash:
      case $backslash:
      case $semicolon:
      case $hash:
      case $equal:
        _checkLenient(); // fall-through
        return false;
      case $openBrace:
      case $closeBrace:
      case $openBracket:
      case $closeBracket:
      case $colon:
      case $comma:
      case $space:
      case $tab:
      case $ff:
      case $cr:
      case $lf:
        return false;
      default:
        return true;
    }
  }

  @override
  String nextName() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    late String result;
    if (p == peekedUnquotedName) {
      result = nextUnquotedValue();
    } else if (p == peekedDoubleQuotedName) {
      result = _nextQuotedValue(doubleQuoteOrSlash);
    } else if (p == peekedSingleQuotedName) {
      result = _nextQuotedValue(singleQuoteOrSlash);
    } else if (p == peekedBufferedName) {
      result = _peekedString!;
    } else {
      throw JsonDataException(
          'Expected a name but was ${peek()} at path ${getPath()}');
    }
    _peeked = peekedNone;
    pathNames[stackSize - 1] = result;
    return result;
  }

  @override
  int selectName(JsonReaderOptions options) {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    if (p < peekedSingleQuotedName || p > peekedBufferedName) {
      return -1;
    }
    if (p == peekedBufferedName) {
      return _findName(_peekedString, options);
    }

    var result = buffer.select(options.doubleQuoteSuffix);
    if (result != -1) {
      _peeked = peekedNone;
      pathNames[stackSize - 1] = options.strings[result];

      return result;
    }

    // The next name may be unnecessary escaped. Save the last recorded path name, so that we
    // can restore the peek state in case we fail to find a match.
    var lastPathName = pathNames[stackSize - 1];

    var nextName = this.nextName();
    result = _findName(nextName, options);

    if (result == -1) {
      _peeked = peekedBufferedName;
      _peekedString = nextName;
      // We can't push the path further, make it seem like nothing happened.
      pathNames[stackSize - 1] = lastPathName;
    }

    return result;
  }

  @override
  void skipName() {
    if (failOnUnknown) {
      throw JsonDataException(
          'Cannot skip unexpected ${peek()} at ${getPath()}');
    }
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    if (p == peekedUnquotedName) {
      skipUnquotedValue();
    } else if (p == peekedDoubleQuotedName) {
      skipQuotedValue(doubleQuoteOrSlash);
    } else if (p == peekedSingleQuotedName) {
      skipQuotedValue(singleQuoteOrSlash);
    } else if (p != peekedBufferedName) {
      throw JsonDataException(
          'Expected a name but was ${peek()} at path ${getPath()}');
    }
    _peeked = peekedNone;
    pathNames[stackSize - 1] = 'null';
  }

  /// If {@code name} is in {@code options} this consumes it and returns its index.
  /// Otherwise this returns -1 and no name is consumed.
  int _findName(String? name, JsonReaderOptions options) {
    for (var i = 0, size = options.strings.length; i < size; i++) {
      if (name == options.strings[i]) {
        _peeked = peekedNone;
        pathNames[stackSize - 1] = name;

        return i;
      }
    }
    return -1;
  }

  @override
  String nextString() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    String? result;
    if (p == peekedUnquoted) {
      result = nextUnquotedValue();
    } else if (p == peekedDoubleQuote) {
      result = _nextQuotedValue(doubleQuoteOrSlash);
    } else if (p == peekedSingleQuote) {
      result = _nextQuotedValue(singleQuoteOrSlash);
    } else if (p == peekedBuffered) {
      result = _peekedString;
      _peekedString = null;
    } else if (p == peekedLong) {
      result = _peekedLong.toString();
    } else if (p == peekedNumber) {
      result = buffer.readUtf8(_peekedNumberLength);
    } else {
      throw JsonDataException(
          'Expected a string but was ${peek()} at path ${getPath()}');
    }
    _peeked = peekedNone;
    pathIndices[stackSize - 1]++;
    return result!;
  }

  @override
  bool nextBoolean() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }
    if (p == peekedTrue) {
      _peeked = peekedNone;
      pathIndices[stackSize - 1]++;
      return true;
    } else if (p == peekedFalse) {
      _peeked = peekedNone;
      pathIndices[stackSize - 1]++;
      return false;
    }
    throw JsonDataException(
        'Expected a boolean but was ${peek()} at path ${getPath()}');
  }

  @override
  double nextDouble() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }

    if (p == peekedLong) {
      _peeked = peekedNone;
      pathIndices[stackSize - 1]++;
      return _peekedLong.toDouble();
    }

    if (p == peekedNumber) {
      _peekedString = buffer.readUtf8(_peekedNumberLength);
    } else if (p == peekedDoubleQuote) {
      _peekedString = _nextQuotedValue(doubleQuoteOrSlash);
    } else if (p == peekedSingleQuote) {
      _peekedString = _nextQuotedValue(singleQuoteOrSlash);
    } else if (p == peekedUnquoted) {
      _peekedString = nextUnquotedValue();
    } else if (p != peekedBuffered) {
      throw JsonDataException(
          'Expected a double but was ${peek()} at path ${getPath()}');
    }

    _peeked = peekedBuffered;
    double result;
    try {
      result = double.parse(_peekedString!);
    } on FormatException catch (_) {
      throw JsonDataException(
          'Expected a double but was $_peekedString at path ${getPath()}');
    }
    if (!lenient && (result.isNaN || result.isInfinite)) {
      throw JsonEncodingException(
          'JSON forbids NaN and infinities: $result at path ${getPath()}');
    }
    _peekedString = null;
    _peeked = peekedNone;
    pathIndices[stackSize - 1]++;
    return result;
  }

  /// Returns the string up to but not including {@code quote}, unescaping any character escape
  /// sequences encountered along the way. The opening quote should have already been read. This
  /// consumes the closing quote, but does not include it in the returned string.
  ///
  /// @throws IOException if any unicode escape sequences are malformed.
  String _nextQuotedValue(List<int> runTerminator) {
    StringBuffer? builder;
    while (true) {
      var index = buffer.indexOfElement(runTerminator, 0);
      if (index == -1) throw syntaxError('Unterminated string');

      // If we've got an escape character, we're going to need a string builder.
      if (buffer.getByte(index) == $backslash) {
        builder ??= StringBuffer();
        builder.write(buffer.readUtf8(index));
        buffer.readByte(); // '\'
        builder.writeCharCode(readEscapeCharacter());
        continue;
      }

      // If it isn't the escape character, it's the quote. Return the string.
      if (builder == null) {
        var result = buffer.readUtf8(index);
        buffer.readByte(); // Consume the quote character.
        return result;
      } else {
        builder.write(buffer.readUtf8(index));
        buffer.readByte(); // Consume the quote character.
        return builder.toString();
      }
    }
  }

  /// Returns an unquoted value as a string. */
  String nextUnquotedValue() {
    var i = buffer.indexOfElement(unquotedStringTerminals, 0);
    return i != -1 ? buffer.readUtf8(i) : buffer.readUtf8(buffer.size);
  }

  void skipQuotedValue(List<int> runTerminator) {
    while (true) {
      var index = buffer.indexOfElement(runTerminator, 0);
      if (index == -1) throw syntaxError('Unterminated string');

      if (buffer.getByte(index) == $backslash) {
        buffer.skip(index + 1);
        readEscapeCharacter();
      } else {
        buffer.skip(index + 1);
        return;
      }
    }
  }

  void skipUnquotedValue() {
    var i = buffer.indexOfElement(unquotedStringTerminals, 0);
    buffer.skip(i != -1 ? i : buffer.size);
  }

  @override
  int nextInt() {
    var p = _peeked;
    if (p == peekedNone) {
      p = _doPeek();
    }

    int result;
    if (p == peekedLong) {
      result = _peekedLong;
      if (_peekedLong != result) {
        // Make sure no precision was lost casting to 'int'.
        throw JsonDataException(
            'Expected an int but was $_peekedLong at path ${getPath()}');
      }
      _peeked = peekedNone;
      pathIndices[stackSize - 1]++;
      return result;
    }

    if (p == peekedNumber) {
      _peekedString = buffer.readUtf8(_peekedNumberLength);
    } else if (p == peekedDoubleQuote || p == peekedSingleQuote) {
      _peekedString = p == peekedDoubleQuote
          ? _nextQuotedValue(doubleQuoteOrSlash)
          : _nextQuotedValue(singleQuoteOrSlash);
      try {
        result = int.parse(_peekedString!);
        _peeked = peekedNone;
        pathIndices[stackSize - 1]++;
        return result;
      } on FormatException catch (_) {
        // Fall back to parse as a double below.
      }
    } else if (p != peekedBuffered) {
      throw JsonDataException(
          'Expected an int but was ${peek()} at path ${getPath()}');
    }

    _peeked = peekedBuffered;
    double asDouble;
    try {
      asDouble = double.parse(_peekedString!);
    } on FormatException catch (_) {
      throw JsonDataException(
          'Expected an int but was $_peekedString  at path ${getPath()}');
    }
    result = asDouble.toInt();
    if (result != asDouble) {
      // Make sure no precision was lost casting to 'int'.
      throw JsonDataException(
          'Expected an int but was $_peekedString at path ${getPath()}');
    }
    _peekedString = null;
    _peeked = peekedNone;
    pathIndices[stackSize - 1]++;
    return result;
  }

  @override
  void close() {
    _peeked = peekedNone;
    scopes[0] = JsonScope.closed;
    stackSize = 1;
    buffer.clear();
  }

  @override
  void skipValue() {
    if (failOnUnknown) {
      throw JsonDataException(
          'Cannot skip unexpected ${peek()} at ${getPath()}');
    }
    var count = 0;
    do {
      var p = _peeked;
      if (p == peekedNone) {
        p = _doPeek();
      }

      if (p == peekedBeginArray) {
        pushScope(JsonScope.emptyArray);
        count++;
      } else if (p == peekedBeginObject) {
        pushScope(JsonScope.emptyObject);
        count++;
      } else if (p == peekedEndArray) {
        count--;
        if (count < 0) {
          throw JsonDataException(
              'Expected a value but was ${peek()} at path ${getPath()}');
        }
        stackSize--;
      } else if (p == peekedEndObject) {
        count--;
        if (count < 0) {
          throw JsonDataException(
              'Expected a value but was ${peek()} at path ${getPath()}');
        }
        stackSize--;
      } else if (p == peekedUnquotedName || p == peekedUnquoted) {
        skipUnquotedValue();
      } else if (p == peekedDoubleQuote || p == peekedDoubleQuotedName) {
        skipQuotedValue(doubleQuoteOrSlash);
      } else if (p == peekedSingleQuote || p == peekedSingleQuotedName) {
        skipQuotedValue(singleQuoteOrSlash);
      } else if (p == peekedNumber) {
        buffer.skip(_peekedNumberLength);
      } else if (p == peekedEof) {
        throw JsonDataException(
            'Expected a value but was ${peek()} at path ${getPath()}');
      }
      _peeked = peekedNone;
    } while (count != 0);

    pathIndices[stackSize - 1]++;
    pathNames[stackSize - 1] = 'null';
  }

  /// Returns the next character in the stream that is neither whitespace nor a
  /// part of a comment. When this returns, the returned character is always at
  /// {buffer.getByte(0)}.
  int _nextNonWhitespace(bool throwOnEof) {
    // This code uses ugly local variables 'p' and 'l' representing the 'pos'
    // and 'limit' fields respectively. Using locals rather than fields saves
    // a few field reads for each whitespace character in a pretty-printed
    // document, resulting in a 5% speedup. We need to flush 'p' to its field
    // before any (potentially indirect) call to fillBuffer() and reread both
    // 'p' and 'l' after any (potentially indirect) call to the same method.
    var p = 0;
    while (buffer.request(p + 1)) {
      var c = buffer.getByte(p++);
      if (c == $lf || c == $space || c == $cr || c == $tab) {
        continue;
      }

      buffer.skip(p - 1);
      if (c == $slash) {
        if (!buffer.request(2)) {
          return c;
        }

        _checkLenient();
        var peek = buffer.getByte(1);
        switch (peek) {
          case $asterisk:
            // skip a /* c-style comment */
            buffer.readByte(); // '/'
            buffer.readByte(); // '*'
            if (!_skipToEndOfBlockComment()) {
              throw syntaxError('Unterminated comment');
            }
            p = 0;
            continue;

          case $slash:
            // skip a // end-of-line comment
            buffer.readByte(); // '/'
            buffer.readByte(); // '/'
            _skipToEndOfLine();
            p = 0;
            continue;

          default:
            return c;
        }
      } else if (c == $hash) {
        // Skip a # hash end-of-line comment. The JSON RFC doesn't specify this behaviour, but it's
        // required to parse existing documents.
        _checkLenient();
        _skipToEndOfLine();
        p = 0;
      } else {
        return c;
      }
    }
    if (throwOnEof) {
      throw StateError('End of input');
    } else {
      return -1;
    }
  }

  void _checkLenient() {
    if (!lenient) {
      throw syntaxError(
          'Use JsonReader.setLenient(true) to accept malformed JSON');
    }
  }

  /// Advances the position until after the next newline character. If the line
  /// is terminated by "\r\n", the '\n' must be consumed as whitespace by the
  /// caller.
  void _skipToEndOfLine() {
    var index = buffer.indexOfElement(lineFeedOrCarriageReturn, 0);
    buffer.skip(index != -1 ? index + 1 : buffer.size);
  }

  /// Skips through the next closing block comment.
  bool _skipToEndOfBlockComment() {
    var index = buffer.indexOfBytes(closingBlockComment, 0);
    var found = index != -1;
    buffer.skip(found ? index + closingBlockComment.length : buffer.size);
    return found;
  }

  @override
  String toString() {
    return 'JsonReader($buffer)';
  }

  /// Unescapes the character identified by the character or characters that immediately follow a
  /// backslash. The backslash '\' should have already been read. This supports both unicode escapes
  /// "u000A" and two-character escapes "\n".
  ///
  /// @throws IOException if any unicode escape sequences are malformed.
  int readEscapeCharacter() {
    if (!buffer.request(1)) {
      throw syntaxError('Unterminated escape sequence');
    }

    var escaped = buffer.readByte();
    switch (escaped) {
      case $u:
        if (!buffer.request(4)) {
          throw Exception('Unterminated escape sequence at path ${getPath()}');
        }
        // Equivalent to Integer.parseInt(stringPool.get(buffer, pos, 4), 16);
        var result = 0;
        for (var i = 0, end = i + 4; i < end; i++) {
          var c = buffer.getByte(i);
          result <<= 4;
          if (c >= $0 && c <= $9) {
            result += c - $0;
          } else if (c >= $a && c <= $f) {
            result += c - $a + 10;
          } else if (c >= $A && c <= $F) {
            result += c - $A + 10;
          } else {
            throw syntaxError('\\u${buffer.readUtf8(4)}');
          }
        }
        buffer.skip(4);
        return result;

      case $t:
        return $tab;

      case $b:
        return $bs;

      case $n:
        return $lf;

      case $r:
        return $cr;

      case $f:
        return $ff;

      case $lf:
      case $singleQuote:
      case $doubleQuote:
      case $backslash:
      case $slash:
        return escaped;

      default:
        if (!lenient) throw syntaxError('Invalid escape sequence: \\$escaped');
        return escaped;
    }
  }
}
