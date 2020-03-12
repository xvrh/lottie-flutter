library jsparser;

import 'src/ast.dart';
import 'src/lexer.dart';
import 'src/parser.dart';
import 'src/annotations.dart';
import 'src/noise.dart';

export 'src/ast.dart';
export 'src/lexer.dart' show ParseError;

/// Parse [text] as a JavaScript program and return its AST.
///
/// Options:
///
/// - [filename]: a string indicating where the source came from (this string has no special syntax or meaning).
///
/// - [firstLine]: line number to associate with the first line of code.
///
/// - [handleNoise]: tolerate noise, such as hash bangs (#!) and HTML comment markers (<!--,-->) (default: true).
///
/// - [annotations]: if true, [Node.parent], [Scope.environment], and [Name.scope] will be initialized (default: true).
///
/// - [parseAsExpression]: if true, parse the input as an expression statement.
Program parsejs(String text,
    {String filename,
      int firstLine= 1,
      bool handleNoise= true,
      bool annotations= true,
      bool parseAsExpression= false}) {
  Offsets offset = new Offsets(0, text.length, firstLine);
  if (handleNoise) {
    offset = trimNoise(text, offset);
  }
  Lexer lexer = new Lexer(text,
      filename: filename,
      currentLine: offset.line,
      index: offset.start,
      endOfFile: offset.end);
  Parser parser = new Parser(lexer);
  Program ast = parseAsExpression
      ? parser.parseExpressionProgram()
      : parser.parseProgram();
  if (annotations) {
    annotateAST(ast);
  }
  ast.filename = filename;
  return ast;
}
