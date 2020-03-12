library parser;

import 'lexer.dart';
import 'ast.dart';

class Parser {
  Parser(this.lexer) {
    token = lexer.scan();
  }

  String get filename => lexer.filename;

  Lexer lexer;
  Token token;

  /// End offset of the last consumed token (i.e. not the one in [token] but the one before that)
  int endOffset;

  dynamic fail({Token tok, String expected, String message}) {
    if (tok == null) tok = token;
    if (message == null) {
      if (expected != null) {
        message = "Expected $expected but found $tok";
      }else{
        message = "Unexpected token $tok";}
    }
    throw new ParseError(
        message, filename, tok.line, tok.startOffset, tok.endOffset);
  }

  /// Returns the current token, and scans the next one.
  Token next() {
    Token t = token;
    endOffset = t.endOffset;
    token = lexer.scan();
    return t;
  }

  /// Consume a semicolon, or if a line-break was here, just pretend there was one here.
  void consumeSemicolon() {
    if (token.type == Token.SEMICOLON) {
      next();
      return;
    }
    if (token.afterLinebreak ||
        token.type == Token.RBRACE ||
        token.type == Token.EOF) {
      return;
    }
    fail(expected: 'semicolon');
  }

  void consume(int type) {
    if (token.type != type) {
      fail(expected: Token.typeToString(type));
    }
    next();
  }

  Token requireNext(int type) {
    if (token.type != type) {
      fail(expected: Token.typeToString(type));
    }
    return next();
  }

  void consumeName(String name) {
    if (token.type != Token.NAME || token.text != name) {
      fail(expected: name);
    }
    next();
  }

  bool peekName(String name) {
    return token.type == Token.NAME && token.text == name;
  }

  bool tryName(String name) {
    if (token.type == Token.NAME && token.text == name) {
      next();
      return true;
    } else {
      return false;
    }
  }

  Name makeName(Token tok) => new Name(tok.value)
    ..start = tok.startOffset
    ..end = tok.endOffset
    ..line = tok.line;

  Name parseName() => makeName(requireNext(Token.NAME));

  ///// FUNCTIONS //////

  List<Name> parseParameters() {
    consume(Token.LPAREN);
    List<Name> list = <Name>[];
    while (token.type != Token.RPAREN) {
      if (list.isNotEmpty) {
        consume(Token.COMMA);
      }
      list.add(parseName());
    }
    consume(Token.RPAREN);
    return list;
  }

  BlockStatement parseFunctionBody() {
    return parseBlock();
  }

  FunctionNode parseFunction() {
    int start = token.startOffset;
    assert(token.text == 'function');
    Token funToken = next();
    Name name;
    if (token.type == Token.NAME) {
      name = parseName();
    }
    List<Name> params = parseParameters();
    BlockStatement body = parseFunctionBody();
    return new FunctionNode(name, params, body)
      ..start = start
      ..end = endOffset
      ..line = funToken.line;
  }

  ///// EXPRESSIONS //////

  Expression parsePrimary() {
    int start = token.startOffset;
    switch (token.type) {
      case Token.NAME:
        switch (token.text) {
          case 'this':
            Token tok = next();
            return new ThisExpression()
              ..start = start
              ..end = endOffset
              ..line = tok.line;
          case 'true':
            Token tok = next();
            return new LiteralExpression(true, 'true')
              ..start = start
              ..end = endOffset
              ..line = tok.line;
          case 'false':
            Token tok = next();
            return new LiteralExpression(false, 'false')
              ..start = start
              ..end = endOffset
              ..line = tok.line;
          case 'null':
            Token tok = next();
            return new LiteralExpression(null, 'null')
              ..start = start
              ..end = endOffset
              ..line = tok.line;
          case 'function':
            return new FunctionExpression(parseFunction());
        }
        Name name = parseName();
        return new NameExpression(name)
          ..start = start
          ..end = endOffset
          ..line = name.line;

      case Token.NUMBER:
        Token tok = next();
        return new LiteralExpression(num.parse(tok.text), tok.text)
          ..start = start
          ..end = endOffset
          ..line = tok.line;

      case Token.STRING:
        Token tok = next();
        return new LiteralExpression(tok.value, tok.text)
          ..start = start
          ..end = endOffset
          ..line = tok.line;

      case Token.LBRACKET:
        return parseArrayLiteral();

      case Token.LBRACE:
        return parseObjectLiteral();

      case Token.LPAREN:
        next();
        Expression exp = parseExpression();
        consume(Token.RPAREN);
        return exp;

      case Token.BINARY:
      case Token.ASSIGN:
        if (token.text == '/' || token.text == '/=') {
          Token regexTok = lexer.scanRegexpBody(token);
          token = lexer.scan();
          endOffset = regexTok.endOffset;
          return new RegexpExpression(regexTok.text)
            ..start = regexTok.startOffset
            ..end = regexTok.endOffset
            ..line = regexTok.line;
        }
        throw fail();

      default:
        throw fail();
    }
  }

  Expression parseArrayLiteral() {
    int start = token.startOffset;
    Token open = requireNext(Token.LBRACKET);
    List<Expression> expressions = <Expression>[];
    while (token.type != Token.RBRACKET) {
      if (token.type == Token.COMMA) {
        next();
        expressions.add(null);
      } else {
        expressions.add(parseAssignment());
        if (token.type != Token.RBRACKET) {
          consume(Token.COMMA);
        }
      }
    }
    consume(Token.RBRACKET);
    return new ArrayExpression(expressions)
      ..start = start
      ..end = endOffset
      ..line = open.line;
  }

  Node makePropertyName(Token tok) {
    int start = tok.startOffset;
    int end = tok.endOffset;
    int line = tok.line;
    switch (tok.type) {
      case Token.NAME:
        return new Name(tok.text)
          ..start = start
          ..end = end
          ..line = line;
      case Token.STRING:
        return new LiteralExpression(tok.value)
          ..raw = tok.text
          ..start = start
          ..end = end
          ..line = line;
      case Token.NUMBER:
        return new LiteralExpression(double.parse(tok.text))
          ..raw = tok.text
          ..start = start
          ..end = end
          ..line = line;
      default:
        throw fail(tok: tok, expected: 'property name');
    }
  }

  Property parseProperty() {
    int start = token.startOffset;
    Token nameTok = next();
    if (token.type == Token.COLON) {
      int line = token.line;
      next(); // skip colon
      Node name = makePropertyName(nameTok);
      Expression value = parseAssignment();
      return new Property(name, value)
        ..start = start
        ..end = endOffset
        ..line = line;
    }
    if (nameTok.type == Token.NAME &&
        (nameTok.text == 'get' || nameTok.text == 'set')) {
      Token kindTok = nameTok;
      String kind =
          kindTok.text == 'get' ? 'get' : 'set'; // internalize the string
      nameTok = next();
      Node name = makePropertyName(nameTok);
      int lparen = token.startOffset;
      List<Name> params = parseParameters();
      BlockStatement body = parseFunctionBody();
      Node value = new FunctionNode(null, params, body)
        ..start = lparen
        ..end = endOffset
        ..line = name.line;
      return new Property(name, value, kind)
        ..start = start
        ..end = endOffset
        ..line = kindTok.line;
    }
    throw fail(expected: 'property', tok: nameTok);
  }

  Expression parseObjectLiteral() {
    int start = token.startOffset;
    Token open = requireNext(Token.LBRACE);
    List<Property> properties = <Property>[];
    while (token.type != Token.RBRACE) {
      if (properties.isNotEmpty) {
        consume(Token.COMMA);
      }
      if (token.type == Token.RBRACE) break; // may end with extra comma
      properties.add(parseProperty());
    }
    requireNext(Token.RBRACE);
    return new ObjectExpression(properties)
      ..start = start
      ..end = endOffset
      ..line = open.line;
  }

  List<Expression> parseArguments() {
    consume(Token.LPAREN);
    List<Expression> list = <Expression>[];
    while (token.type != Token.RPAREN) {
      if (list.length > 0) {
        consume(Token.COMMA);
      }
      list.add(parseAssignment());
    }
    consume(Token.RPAREN);
    return list;
  }

  Expression parseMemberExpression(Token newTok) {
    int start = token.startOffset;
    Expression exp = parsePrimary();
    loop:
    while (true) {
      int line = token.line;
      switch (token.type) {
        case Token.DOT:
          next();
          Name name = parseName();
          exp = new MemberExpression(exp, name)
            ..start = start
            ..end = endOffset
            ..line = line;
          break;

        case Token.LBRACKET:
          next();
          Expression index = parseExpression();
          requireNext(Token.RBRACKET);
          exp = new IndexExpression(exp, index)
            ..start = start
            ..end = endOffset
            ..line = line;
          break;

        case Token.LPAREN:
          List<Expression> args = parseArguments();
          if (newTok != null) {
            start = newTok.startOffset;
            exp = new CallExpression.newCall(exp, args)
              ..start = start
              ..end = endOffset
              ..line = line;
            newTok = null;
          } else {
            exp = new CallExpression(exp, args)
              ..start = start
              ..end = endOffset
              ..line = line;
          }
          break;

        default:
          break loop;
      }
    }
    if (newTok != null) {
      exp = new CallExpression.newCall(exp, <Expression>[])
        ..start = newTok.startOffset
        ..end = endOffset
        ..line = newTok.line;
    }
    return exp;
  }

  Expression parseNewExpression() {
    assert(token.text == 'new');
    Token newTok = next();
    if (peekName('new')) {
      Expression exp = parseNewExpression();
      return new CallExpression.newCall(exp, <Expression>[])
        ..start = newTok.startOffset
        ..end = endOffset
        ..line = newTok.line;
    }
    return parseMemberExpression(newTok);
  }

  Expression parseLeftHandSide() {
    if (peekName('new')) {
      return parseNewExpression();
    } else {
      return parseMemberExpression(null);
    }
  }

  Expression parsePostfix() {
    int start = token.startOffset;
    Expression exp = parseLeftHandSide();
    if (token.type == Token.UPDATE && !token.afterLinebreak) {
      Token operator = next();
      exp = new UpdateExpression.postfix(operator.text, exp)
        ..start = start
        ..end = endOffset
        ..line = operator.line;
    }
    return exp;
  }

  Expression parseUnary() {
    switch (token.type) {
      case Token.UNARY:
        Token operator = next();
        Expression exp = parseUnary();
        return new UnaryExpression(operator.text, exp)
          ..start = operator.startOffset
          ..end = endOffset
          ..line = operator.line;

      case Token.UPDATE:
        Token operator = next();
        Expression exp = parseUnary();
        return new UpdateExpression.prefix(operator.text, exp)
          ..start = operator.startOffset
          ..end = endOffset
          ..line = operator.line;

      case Token.NAME:
        if (token.text == 'delete' ||
            token.text == 'void' ||
            token.text == 'typeof') {
          Token operator = next();
          Expression exp = parseUnary();
          return new UnaryExpression(operator.text, exp)
            ..start = operator.startOffset
            ..end = endOffset
            ..line = operator.line;
        }
        break;
    }
    return parsePostfix();
  }

  Expression parseBinary(int minPrecedence, bool allowIn) {
    int start = token.startOffset;
    Expression exp = parseUnary();
    while (token.binaryPrecedence >= minPrecedence) {
      if (token.type == Token.NAME) {
        // All name tokens are given precedence of RELATIONAL
        // Weed out name tokens that are not actually binary operators
        if (token.value != 'instanceof' && (token.value != 'in' || !allowIn))
          break;
      }
      Token operator = next();
      Expression right = parseBinary(operator.binaryPrecedence + 1, allowIn);
      exp = new BinaryExpression(exp, operator.text, right)
        ..start = start
        ..end = endOffset
        ..line = operator.line;
    }
    return exp;
  }

  Expression parseConditional(bool allowIn) {
    int start = token.startOffset;
    Expression exp = parseBinary(Precedence.EXPRESSION, allowIn);
    if (token.type == Token.QUESTION) {
      Token quest = next();
      Expression thenExp = parseAssignment();
      consume(Token.COLON);
      Expression elseExp = parseAssignment(allowIn: allowIn);
      exp = new ConditionalExpression(exp, thenExp, elseExp)
        ..start = start
        ..end = endOffset
        ..line = quest.line;
    }
    return exp;
  }

  Expression parseAssignment({bool allowIn: true}) {
    int start = token.startOffset;
    Expression exp = parseConditional(allowIn);
    if (token.type == Token.ASSIGN) {
      Token operator = next();
      Expression right = parseAssignment(allowIn: allowIn);
      exp = new AssignmentExpression(exp, operator.text, right)
        ..start = start
        ..end = endOffset
        ..line = operator.line;
    }
    return exp;
  }

  Expression parseExpression({bool allowIn: true}) {
    int start = token.startOffset;
    Expression exp = parseAssignment(allowIn: allowIn);
    if (token.type == Token.COMMA) {
      List<Expression> expressions = <Expression>[exp];
      while (token.type == Token.COMMA) {
        next();
        expressions.add(parseAssignment(allowIn: allowIn));
      }
      exp = new SequenceExpression(expressions)
        ..start = start
        ..end = endOffset
        ..line = expressions.first.line;
    }
    return exp;
  }

  ////// STATEMENTS /////

  BlockStatement parseBlock() {
    int start = token.startOffset;
    int line = token.line;
    consume(Token.LBRACE);
    List<Statement> list = <Statement>[];
    while (token.type != Token.RBRACE) {
      list.add(parseStatement());
    }
    consume(Token.RBRACE);
    return new BlockStatement(list)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  VariableDeclaration parseVariableDeclarationList({bool allowIn: true}) {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'var');
    consume(Token.NAME);
    List<VariableDeclarator> list = <VariableDeclarator>[];
    while (true) {
      Name name = parseName();
      Expression init = null;
      if (token.type == Token.ASSIGN) {
        if (token.text != '=') {
          fail(message: 'Compound assignment in initializer');
        }
        next();
        init = parseAssignment(allowIn: allowIn);
      }
      list.add(new VariableDeclarator(name, init)
        ..start = name.start
        ..end = endOffset
        ..line = name.line);
      if (token.type != Token.COMMA) break;
      next();
    }
    return new VariableDeclaration(list)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  VariableDeclaration parseVariableDeclarationStatement() {
    VariableDeclaration decl = parseVariableDeclarationList();
    consumeSemicolon();
    return decl..end = endOffset; // overwrite end so semicolon is included
  }

  Statement parseEmptyStatement() {
    Token semi = requireNext(Token.SEMICOLON);
    return new EmptyStatement()
      ..start = semi.startOffset
      ..end = semi.endOffset
      ..line = semi.line;
  }

  Statement parseExpressionStatement() {
    int start = token
        .startOffset; // Note: not the same as exp.start due to removal of parentheses
    Expression exp = parseExpression();
    consumeSemicolon();
    return new ExpressionStatement(exp)
      ..start = start
      ..end = endOffset
      ..line = exp.line;
  }

  Statement parseExpressionOrLabeledStatement() {
    int start = token
        .startOffset; // Note: not the same as exp.start due to removal of parentheses
    Expression exp = parseExpression();
    if (token.type == Token.COLON &&
        exp is NameExpression &&
        exp.start == start) {
      Name name = exp.name;
      next(); // skip the colon
      Statement inner = parseStatement();
      return new LabeledStatement(name, inner);
    } else {
      consumeSemicolon();
      return new ExpressionStatement(exp)
        ..start = start
        ..end = endOffset
        ..line = exp.line;
    }
  }

  Statement parseIf() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'if');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Expression condition = parseExpression();
    consume(Token.RPAREN);
    Statement thenBody = parseStatement();
    Statement elseBody;
    if (tryName('else')) {
      elseBody = parseStatement();
    }
    return new IfStatement(condition, thenBody, elseBody)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseDoWhile() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'do');
    consume(Token.NAME);
    Statement body = parseStatement();
    consumeName('while');
    consume(Token.LPAREN);
    Expression condition = parseExpression();
    consume(Token.RPAREN);
    consumeSemicolon();
    return new DoWhileStatement(body, condition)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseWhile() {
    int line = token.line;
    int start = token.startOffset;
    assert(token.text == 'while');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Expression condition = parseExpression();
    consume(Token.RPAREN);
    Statement body = parseStatement();
    return new WhileStatement(condition, body)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseFor() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'for');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Node exp1;
    if (peekName('var')) {
      exp1 = parseVariableDeclarationList(allowIn: false);
    } else if (token.type != Token.SEMICOLON) {
      exp1 = parseExpression(allowIn: false);
    }
    if (exp1 != null && tryName('in')) {
      if (exp1 is VariableDeclaration && exp1.declarations.length > 1) {
        fail(message: 'Multiple vars declared in for-in loop');
      }
      Expression exp2 = parseExpression();
      consume(Token.RPAREN);
      Statement body = parseStatement();
      return new ForInStatement(exp1, exp2, body)
        ..start = start
        ..end = endOffset
        ..line = line;
    } else {
      consume(Token.SEMICOLON);
      Expression exp2, exp3;
      if (token.type != Token.SEMICOLON) {
        exp2 = parseExpression();
      }
      consume(Token.SEMICOLON);
      if (token.type != Token.RPAREN) {
        exp3 = parseExpression();
      }
      consume(Token.RPAREN);
      Statement body = parseStatement();
      return new ForStatement(exp1, exp2, exp3, body)
        ..start = start
        ..end = endOffset
        ..line = line;
    }
  }

  Statement parseContinue() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'continue');
    consume(Token.NAME);
    Name name;
    if (token.type == Token.NAME && !token.afterLinebreak) {
      name = parseName();
    }
    consumeSemicolon();
    return new ContinueStatement(name)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseBreak() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'break');
    consume(Token.NAME);
    Name name;
    if (token.type == Token.NAME && !token.afterLinebreak) {
      name = parseName();
    }
    consumeSemicolon();
    return new BreakStatement(name)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseReturn() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'return');
    consume(Token.NAME);
    Expression exp;
    if (token.type != Token.SEMICOLON &&
        token.type != Token.RBRACE &&
        token.type != Token.EOF &&
        !token.afterLinebreak) {
      exp = parseExpression();
    }
    consumeSemicolon();
    return new ReturnStatement(exp)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseWith() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'with');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Expression exp = parseExpression();
    consume(Token.RPAREN);
    Statement body = parseStatement();
    return new WithStatement(exp, body)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseSwitch() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'switch');
    consume(Token.NAME);
    consume(Token.LPAREN);
    Expression argument = parseExpression();
    consume(Token.RPAREN);
    consume(Token.LBRACE);
    List<SwitchCase> cases = <SwitchCase>[];
    cases.add(parseSwitchCaseHead());
    while (token.type != Token.RBRACE) {
      if (peekName('case') || peekName('default')) {
        cases.add(parseSwitchCaseHead());
      } else {
        cases.last.body.add(parseStatement());
        cases.last.end = endOffset;
      }
    }
    consume(Token.RBRACE);
    return new SwitchStatement(argument, cases)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  /// Parses a single 'case E:' or 'default:' without the following statements
  SwitchCase parseSwitchCaseHead() {
    int start = token.startOffset;
    int line = token.line;
    Token tok = requireNext(Token.NAME);
    if (tok.text == 'case') {
      Expression value = parseExpression();
      consume(Token.COLON);
      return new SwitchCase(value, <Statement>[])
        ..start = start
        ..end = endOffset
        ..line = line;
    } else if (tok.text == 'default') {
      consume(Token.COLON);
      return new SwitchCase(null, <Statement>[])
        ..start = start
        ..end = endOffset
        ..line = line;
    } else {
      throw fail();
    }
  }

  Statement parseThrow() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'throw');
    consume(Token.NAME);
    Expression exp = parseExpression();
    consumeSemicolon();
    return new ThrowStatement(exp)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseTry() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'try');
    consume(Token.NAME);
    BlockStatement body = parseBlock();
    CatchClause handler;
    BlockStatement finalizer;
    if (peekName('catch')) {
      Token catchTok = next();
      consume(Token.LPAREN);
      Name name = parseName();
      consume(Token.RPAREN);
      BlockStatement catchBody = parseBlock();
      handler = new CatchClause(name, catchBody)
        ..start = catchTok.startOffset
        ..end = endOffset
        ..line = catchTok.line;
    }
    if (tryName('finally')) {
      finalizer = parseBlock();
    }
    return new TryStatement(body, handler, finalizer)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseDebuggerStatement() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'debugger');
    consume(Token.NAME);
    consumeSemicolon();
    return new DebuggerStatement()
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseFunctionDeclaration() {
    int start = token.startOffset;
    int line = token.line;
    assert(token.text == 'function');
    FunctionNode func = parseFunction();
    if (func.name == null) {
      fail(message: 'Function declaration must have a name');
    }
    return new FunctionDeclaration(func)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Statement parseStatement() {
    if (token.type == Token.LBRACE) return parseBlock();
    if (token.type == Token.SEMICOLON) return parseEmptyStatement();
    if (token.type != Token.NAME) return parseExpressionStatement();
    switch (token.value) {
      case 'var':
        return parseVariableDeclarationStatement();
      case 'if':
        return parseIf();
      case 'do':
        return parseDoWhile();
      case 'while':
        return parseWhile();
      case 'for':
        return parseFor();
      case 'continue':
        return parseContinue();
      case 'break':
        return parseBreak();
      case 'return':
        return parseReturn();
      case 'with':
        return parseWith();
      case 'switch':
        return parseSwitch();
      case 'throw':
        return parseThrow();
      case 'try':
        return parseTry();
      case 'debugger':
        return parseDebuggerStatement();
      case 'function':
        return parseFunctionDeclaration();
      default:
        return parseExpressionOrLabeledStatement();
    }
  }

  Program parseProgram() {
    int start = token.startOffset;
    int line = token.line;
    List<Statement> statements = <Statement>[];
    while (token.type != Token.EOF) {
      statements.add(parseStatement());
    }
    if (endOffset == null) {
      endOffset = start;
    }
    return new Program(statements)
      ..start = start
      ..end = endOffset
      ..line = line;
  }

  Program parseExpressionProgram() {
    int start = token.startOffset;
    int line = token.line;
    var statement = parseExpressionStatement();
    consume(Token.EOF);
    if (endOffset == null) {
      endOffset = start;
    }
    return new Program(<Statement>[statement])
      ..start = start
      ..end = endOffset
      ..line = line;
  }
}
