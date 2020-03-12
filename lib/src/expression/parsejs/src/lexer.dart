library lexer;

import 'charcode.dart' as char;

class ParseError {
  String message;
  String filename;
  int line; // 1-based line number.
  int startOffset;
  int endOffset;

  ParseError(
      this.message, this.filename, this.line, this.startOffset, this.endOffset);

  String get location => filename == null ? 'Line $line' : '$filename:$line';

  String toString() => '[$location] $message';
}

class Token {
  int startOffset;
  int line;
  int type;
  String
      text; // text exactly as in source code or null for EOF or tokens with type > 31
  bool afterLinebreak; // true if first token after a linebreak
  String
      value; // value of identifier or string literal after escapes, null for other tokens

  /// For tokens that can be used as binary operators, this indicates their relative precedence.
  /// Set to -100 for other tokens.
  /// Token type can be BINARY, or UNARY (+,-) or NAME (instanceof,in).
  int binaryPrecedence = -100;

  Token(this.startOffset, this.line, this.type, this.afterLinebreak, this.text);

  String toString() => text != null ? text : typeToString(type);

  String get detailedString => "[$startOffset, $text, $type, $afterLinebreak]";

  int get endOffset => startOffset + (text == null ? 1 : text.length);

  static const int EOF = 0;
  static const int NAME = 1;
  static const int NUMBER = 2;
  static const int BINARY =
      3; // does not contain unary operators +,- or names instanceof, in (but binaryPrecedence is set for these)
  static const int ASSIGN = 4; // also compound assignment operators
  static const int UPDATE = 5; // ++ and --
  static const int UNARY =
      6; // all unary operators except the names void, delete
  static const int STRING = 7;
  static const int REGEXP = 8;

  // Tokens without a text have type equal to their corresponding char code
  // All these are >31
  static const int LPAREN = char.LPAREN;
  static const int RPAREN = char.RPAREN;
  static const int LBRACE = char.LBRACE;
  static const int RBRACE = char.RBRACE;
  static const int LBRACKET = char.LBRACKET;
  static const int RBRACKET = char.RBRACKET;
  static const int COMMA = char.COMMA;
  static const int COLON = char.COLON;
  static const int SEMICOLON = char.SEMICOLON;
  static const int DOT = char.DOT;
  static const int QUESTION = char.QUESTION;

  static String typeToString(int type) {
    if (type > 31) return "'${new String.fromCharCode(type)}'";
    switch (type) {
      case EOF:
        return 'EOF';
      case NAME:
        return 'name';
      case NUMBER:
        return 'number';
      case BINARY:
        return 'binary operator';
      case ASSIGN:
        return 'assignment operator';
      case UPDATE:
        return 'update operator';
      case UNARY:
        return 'unary operator';
      case STRING:
        return 'string literal';
      default:
        return '[type $type]';
    }
  }
}

class Precedence {
  static const int EXPRESSION = 0;
  static const int CONDITIONAL = 1;
  static const int LOGICAL_OR = 2;
  static const int LOGICAL_AND = 3;
  static const int BITWISE_OR = 4;
  static const int BITWISE_XOR = 5;
  static const int BITWISE_AND = 6;
  static const int EQUALITY = 7;
  static const int RELATIONAL = 8;
  static const int SHIFT = 9;
  static const int ADDITIVE = 10;
  static const int MULTIPLICATIVE = 11;
}

bool isLetter(int x) =>
    (char.$a <= x && x <= char.$z) || (char.$A <= x && x <= char.$Z);

bool isDigit(int x) =>
    char.$0 <= x &&
    x <= char.$9; // Does NOT and should not include unicode special digits

bool isNameStart(int x) =>
    isLetter(x) || x == char.DOLLAR || x == char.UNDERSCORE;

bool isNamePart(int x) =>
    char.$a <= x && x <= char.$z ||
    char.$A <= x && x <= char.$Z ||
    char.$0 <= x && x <= char.$9 ||
    x == char.DOLLAR ||
    x == char.UNDERSCORE;

bool isFancyNamePart(int x) => x == char.ZWNJ || x == char.ZWJ || x == char.BOM;

/// Ordinary whitespace (not line terminators)
bool isWhitespace(int x) {
  switch (x) {
    case char.SPACE:
    case char.TAB:
    case char.VTAB:
    case char.FF:
    case char.BOM:
      return true;

    default:
      return false;
  }
}

bool isEOL(int x) {
  switch (x) {
    case char.LF:
    case char.CR:
    case char.LS:
    case char.PS:
    case char.NULL:
      return true;
    default:
      return false;
  }
}

class Lexer {
  Lexer(String text,
      {this.filename, this.currentLine: 1, this.index: 0, this.endOfFile}) {
    input = text.codeUnits;
    if (endOfFile == null) {
      endOfFile = input.length;
    }
  }

  List<int> input;
  int index = 0;
  int endOfFile;
  int tokenStart;
  int tokenLine;
  int currentLine; // We use 1-based line numbers.
  bool seenLinebreak;
  String filename;

  int get current => index == endOfFile ? char.NULL : input[index];

  int next() {
    ++index;
    return index == endOfFile ? char.NULL : input[index];
  }

  void fail(String message) {
    throw new ParseError(message, filename, currentLine, tokenStart, index);
  }

  Token emitToken(int type, [String value]) {
    return new Token(tokenStart, tokenLine, type, seenLinebreak, value);
  }

  Token emitValueToken(int type) {
    String value = new String.fromCharCodes(input.getRange(tokenStart, index));
    return new Token(tokenStart, tokenLine, type, seenLinebreak, value);
  }

  Token scanNumber(int x) {
    if (x == char.$0) {
      x = next();
      if (x == char.$x || x == char.$X) {
        x = next();
        return scanHexNumber(x);
      }
    }
    while (isDigit(x)) {
      x = next();
    }
    if (x == char.DOT) {
      x = next();
      return scanDecimalPart(x);
    }
    return scanExponentPart(x);
  }

  Token scanDecimalPart(int x) {
    while (isDigit(x)) {
      x = next();
    }
    return scanExponentPart(x);
  }

  Token scanExponentPart(int x) {
    if (x == char.$e || x == char.$E) {
      x = next();
      if (x == char.PLUS || x == char.MINUS) {
        x = next();
      }
      while (isDigit(x)) {
        x = next();
      }
    }
    return emitValueToken(Token.NUMBER);
  }

  Token scanHexNumber(int x) {
    while (isDigit(x) ||
        char.$a <= x && x <= char.$f ||
        char.$A <= x && x <= char.$F) {
      x = next();
    }
    return emitValueToken(Token.NUMBER);
  }

  Token scanName(int x) {
    while (true) {
      if (x == char.BACKSLASH) return scanComplexName(x);
      if (!isNamePart(x)) {
        Token tok = emitValueToken(Token.NAME);
        tok.value = tok.text;
        return tok..binaryPrecedence = Precedence.RELATIONAL;
      }
      x = next();
    }
  }

  Token scanComplexName(int x) {
    // name with unicode escape sequences
    List<int> buffer = new List<int>.from(input.getRange(tokenStart, index));
    while (true) {
      if (x == char.BACKSLASH) {
        x = next();
        if (x != char.$u) {
          fail("Invalid escape sequence in name");
        }
        ++index;
        buffer.add(scanHexSequence(4));
        x = current;
      } else if (isNamePart(x)) {
        buffer.add(x);
        x = next();
      } else {
        break;
      }
    }
    Token tok = emitValueToken(Token.NAME);
    tok.value = new String.fromCharCodes(buffer);
    return tok..binaryPrecedence = Precedence.RELATIONAL;
  }

  /// [index] must point to the first hex digit.
  /// It will be advanced to point AFTER the hex sequence (i.e. index += count).
  int scanHexSequence(int count) {
    int x = current;
    int value = 0;
    for (int i = 0; i < count; i++) {
      if (char.$0 <= x && x <= char.$9) {
        value = (value << 4) + (x - char.$0);
      } else if (char.$a <= x && x <= char.$f) {
        value = (value << 4) + (x - char.$a + 10);
      } else if (char.$A <= x && x <= char.$F) {
        value = (value << 4) + (x - char.$A + 10);
      } else {
        fail('Invalid hex sequence');
      }
      x = next();
    }
    return value;
  }

  Token scan() {
    seenLinebreak = false;
    scanLoop:
    while (true) {
      int x = current;
      tokenStart = index;
      tokenLine = currentLine;
      switch (x) {
        case char.NULL:
          return emitToken(Token
              .EOF); // (will produce infinite EOF tokens if pressed for more tokens)

        case char
            .SPACE: // Note: Exotic whitespace symbols are handled in the default clause.
        case char.TAB:
          ++index;
          continue;

        case char.CR:
          seenLinebreak = true;
          ++currentLine;
          x = next();
          if (x == char.LF) {
            ++index; // count as single linebreak
          }
          continue;

        case char.LF:
        case char.LS:
        case char.PS:
          seenLinebreak = true;
          ++currentLine;
          ++index;
          continue;

        case char.SLASH:
          x = next(); // consume "/"
          if (x == char.SLASH) {
            // "//" comment
            x = next();
            while (!isEOL(x)) {
              x = next();
            }
            continue; // line number will be when reading the LF,CR,LS,PS or EOF
          }
          if (x == char.STAR) {
            // "/*" comment
            x = current;
            while (true) {
              switch (x) {
                case char.STAR:
                  x = next();
                  if (x == char.SLASH) {
                    ++index; // skip final slash
                    continue scanLoop; // Finished block comment.
                  }
                  break;
                case char.NULL:
                  fail("Unterminated block comment");
                  break;
                case char.CR:
                  ++currentLine;
                  x = next();
                  if (x == char.LF) {
                    x = next(); // count as one line break
                  }
                  break;
                case char.LS:
                case char.LF:
                case char.PS:
                  ++currentLine;
                  x = next();
                  break;
                default:
                  x = next();
              }
            }
          }
          // parser will recognize these as potential regexp heads
          if (x == char.EQ) {
            // "/="
            ++index;
            return emitToken(Token.ASSIGN, '/=');
          }
          return emitToken(Token.BINARY, '/')
            ..binaryPrecedence = Precedence.MULTIPLICATIVE;

        case char.PLUS:
          x = next();
          if (x == char.PLUS) {
            ++index;
            return emitToken(Token.UPDATE, '++');
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '+=');
          }
          return emitToken(Token.UNARY, '+')
            ..binaryPrecedence = Precedence.ADDITIVE;

        case char.MINUS:
          x = next();
          if (x == char.MINUS) {
            ++index;
            return emitToken(Token.UPDATE, '--');
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '-=');
          }
          return emitToken(Token.UNARY, '-')
            ..binaryPrecedence = Precedence.ADDITIVE;

        case char.STAR:
          x = next();
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '*=');
          }
          return emitToken(Token.BINARY, '*')
            ..binaryPrecedence = Precedence.MULTIPLICATIVE;

        case char.PERCENT:
          x = next();
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '%=');
          }
          return emitToken(Token.BINARY, '%')
            ..binaryPrecedence = Precedence.MULTIPLICATIVE;

        case char.LT:
          x = next();
          if (x == char.LT) {
            x = next();
            if (x == char.EQ) {
              ++index;
              return emitToken(Token.ASSIGN, '<<=');
            }
            return emitToken(Token.BINARY, '<<')
              ..binaryPrecedence = Precedence.SHIFT;
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.BINARY, '<=')
              ..binaryPrecedence = Precedence.RELATIONAL;
          }
          return emitToken(Token.BINARY, '<')
            ..binaryPrecedence = Precedence.RELATIONAL;

        case char.GT:
          x = next();
          if (x == char.GT) {
            x = next();
            if (x == char.GT) {
              x = next();
              if (x == char.EQ) {
                ++index;
                return emitToken(Token.ASSIGN, '>>>=');
              }
              return emitToken(Token.BINARY, '>>>')
                ..binaryPrecedence = Precedence.SHIFT;
            }
            if (x == char.EQ) {
              ++index;
              return emitToken(Token.ASSIGN, '>>=');
            }
            return emitToken(Token.BINARY, '>>')
              ..binaryPrecedence = Precedence.SHIFT;
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.BINARY, '>=')
              ..binaryPrecedence = Precedence.RELATIONAL;
          }
          return emitToken(Token.BINARY, '>')
            ..binaryPrecedence = Precedence.RELATIONAL;

        case char.HAT:
          x = next();
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '^=');
          }
          return emitToken(Token.BINARY, '^')
            ..binaryPrecedence = Precedence.BITWISE_XOR;

        case char.TILDE:
          ++index;
          return emitToken(Token.UNARY, '~');

        case char.BAR:
          x = next();
          if (x == char.BAR) {
            ++index;
            return emitToken(Token.BINARY, '||')
              ..binaryPrecedence = Precedence.LOGICAL_OR;
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '|=');
          }
          return emitToken(Token.BINARY, '|')
            ..binaryPrecedence = Precedence.BITWISE_OR;

        case char.AMPERSAND:
          x = next();
          if (x == char.AMPERSAND) {
            ++index;
            return emitToken(Token.BINARY, '&&')
              ..binaryPrecedence = Precedence.LOGICAL_AND;
          }
          if (x == char.EQ) {
            ++index;
            return emitToken(Token.ASSIGN, '&=');
          }
          return emitToken(Token.BINARY, '&')
            ..binaryPrecedence = Precedence.BITWISE_AND;

        case char.EQ:
          x = next();
          if (x == char.EQ) {
            x = next();
            if (x == char.EQ) {
              ++index;
              return emitToken(Token.BINARY, '===')
                ..binaryPrecedence = Precedence.EQUALITY;
            }
            return emitToken(Token.BINARY, '==')
              ..binaryPrecedence = Precedence.EQUALITY;
          }
          return emitToken(Token.ASSIGN, '=');

        case char.BANG:
          x = next();
          if (x == char.EQ) {
            x = next();
            if (x == char.EQ) {
              ++index;
              return emitToken(Token.BINARY, '!==')
                ..binaryPrecedence = Precedence.EQUALITY;
            }
            return emitToken(Token.BINARY, '!=')
              ..binaryPrecedence = Precedence.EQUALITY;
          }
          return emitToken(Token.UNARY, '!');

        case char.DOT:
          x = next();
          if (isDigit(x)) {
            return scanDecimalPart(x);
          }
          return emitToken(Token.DOT);

        case char.SQUOTE:
        case char.DQUOTE:
          return scanStringLiteral(x);

        case char.LPAREN:
        case char.RPAREN:
        case char.LBRACKET:
        case char.RBRACKET:
        case char.LBRACE:
        case char.RBRACE:
        case char.COMMA:
        case char.COLON:
        case char.SEMICOLON:
        case char.QUESTION:
          ++index;
          return emitToken(x);

        case char.BACKSLASH:
          return scanComplexName(x);

        default:
          if (isNameStart(x)) return scanName(x);
          if (isDigit(x)) return scanNumber(x);
          if (isWhitespace(x)) {
            ++index;
            continue;
          }
          fail(
              "Unrecognized character: '${new String.fromCharCode(x)}' (UTF+${x.toRadixString(16)})");
      }
    }
  }

  /// Scan a regular expression literal, where the opening token has already been scanned
  /// This is called directly from the parser.
  /// The opening token [slash] can be a "/" or a "/=" token
  Token scanRegexpBody(Token slash) {
    bool inCharClass =
        false; // If true, we are inside a bracket. A slash in here does not terminate the literal. They are not nestable.
    int x = current;
    while (inCharClass || x != char.SLASH) {
      switch (x) {
        case char.NULL:
          fail("Unterminated regexp");
          break;
        case char.LBRACKET:
          inCharClass = true;
          break;
        case char.RBRACKET:
          inCharClass = false;
          break;
        case char.BACKSLASH:
          x = next();
          if (isEOL(x)) fail("Unterminated regexp");
          break;
        case char.CR:
        case char.LF:
        case char.LS:
        case char.PS:
          fail("Unterminated regexp");
      }
      x = next();
    }
    x = next(); // Move past the terminating "/"
    while (isNamePart(x)) {
      // Parse flags
      x = next();
    }
    return emitToken(Token.REGEXP,
        new String.fromCharCodes(input.getRange(slash.startOffset, index)));
  }

  Token scanStringLiteral(int x) {
    List<int> buffer =
        <int>[]; // String value without quotes, after resolving escapes.
    int quote = x;
    x = next();
    while (x != quote) {
      if (x == char.BACKSLASH) {
        x = next();
        switch (x) {
          case char.$b:
            buffer.add(char.BS);
            x = next();
            break;
          case char.$f:
            buffer.add(char.FF);
            x = next();
            break;
          case char.$n:
            buffer.add(char.LF);
            x = next();
            break;
          case char.$r:
            buffer.add(char.CR);
            x = next();
            break;
          case char.$t:
            buffer.add(char.TAB);
            x = next();
            break;
          case char.$v:
            buffer.add(char.VTAB);
            x = next();
            break;

          case char.$x:
            ++index;
            buffer.add(scanHexSequence(2));
            x = current;
            break;

          case char.$u:
            ++index;
            buffer.add(scanHexSequence(4));
            x = current;
            break;

          case char.$0:
          case char.$1:
          case char.$2:
          case char.$3:
          case char.$4:
          case char.$5:
          case char.$6:
          case char.$7: // Octal escape
            int value = (x - char.$0);
            x = next();
            while (isDigit(x)) {
              int nextValue = (value << 3) + (x - char.$0);
              if (nextValue > 127) break;
              value = nextValue;
              x = next();
            }
            buffer.add(value);
            break; // OK

          case char.LF:
          case char.LS:
          case char.PS:
            ++currentLine;
            x = next(); // just continue on next line
            break;

          case char.CR:
            ++currentLine;
            x = next();
            if (x == char.LF) {
              x = next(); // Escape entire CR-LF sequence
            }
            break;

          case char.SQUOTE:
          case char.DQUOTE:
          case char.BACKSLASH:
          default:
            buffer.add(x);
            x = next();
            break;
        }
      } else if (isEOL(x)) {
        // Note: EOF counts as an EOL
        fail("Unterminated string literal");
      } else {
        buffer.add(x); // ordinary char
        x = next();
      }
    }
    ++index; // skip ending quote
    String value = new String.fromCharCodes(buffer);
    return emitValueToken(Token.STRING)..value = value;
  }
}
