part of ast;

/// Visitor interface for AST nodes.
///
/// Also see [BaseVisitor] and [RecursiveVisitor].
abstract class Visitor<T> {
  /// Shorthand for `node.visitBy(this)`.
  T visit(Node node) => node.visitBy(this);

  T visitPrograms(Programs node);
  T visitProgram(Program node);
  T visitFunctionNode(FunctionNode node);
  T visitName(Name node);

  T visitEmptyStatement(EmptyStatement node);
  T visitBlock(BlockStatement node);
  T visitExpressionStatement(ExpressionStatement node);
  T visitIf(IfStatement node);
  T visitLabeledStatement(LabeledStatement node);
  T visitBreak(BreakStatement node);
  T visitContinue(ContinueStatement node);
  T visitWith(WithStatement node);
  T visitSwitch(SwitchStatement node);
  T visitSwitchCase(SwitchCase node);
  T visitReturn(ReturnStatement node);
  T visitThrow(ThrowStatement node);
  T visitTry(TryStatement node);
  T visitCatchClause(CatchClause node);
  T visitWhile(WhileStatement node);
  T visitDoWhile(DoWhileStatement node);
  T visitFor(ForStatement node);
  T visitForIn(ForInStatement node);
  T visitFunctionDeclaration(FunctionDeclaration node);
  T visitVariableDeclaration(VariableDeclaration node);
  T visitVariableDeclarator(VariableDeclarator node);
  T visitDebugger(DebuggerStatement node);

  T visitThis(ThisExpression node);
  T visitArray(ArrayExpression node);
  T visitObject(ObjectExpression node);
  T visitProperty(Property node);
  T visitFunctionExpression(FunctionExpression node);
  T visitSequence(SequenceExpression node);
  T visitUnary(UnaryExpression node);
  T visitBinary(BinaryExpression node);
  T visitAssignment(AssignmentExpression node);
  T visitUpdateExpression(UpdateExpression node);
  T visitConditional(ConditionalExpression node);
  T visitCall(CallExpression node);
  T visitMember(MemberExpression node);
  T visitIndex(IndexExpression node);
  T visitNameExpression(NameExpression node);
  T visitLiteral(LiteralExpression node);
  T visitRegexp(RegexpExpression node);
}

/// Implementation of [Visitor] which redirects each `visit` method to a method [defaultNode].
///
/// This is convenient when only a couple of `visit` methods are needed
/// and a default action can be taken for all other nodes.
class BaseVisitor<T> implements Visitor<T> {
  T defaultNode(Node node) => null;

  T visit(Node node) => node.visitBy(this);

  T visitPrograms(Programs node) => defaultNode(node);
  T visitProgram(Program node) => defaultNode(node);
  T visitFunctionNode(FunctionNode node) => defaultNode(node);
  T visitName(Name node) => defaultNode(node);

  T visitEmptyStatement(EmptyStatement node) => defaultNode(node);
  T visitBlock(BlockStatement node) => defaultNode(node);
  T visitExpressionStatement(ExpressionStatement node) => defaultNode(node);
  T visitIf(IfStatement node) => defaultNode(node);
  T visitLabeledStatement(LabeledStatement node) => defaultNode(node);
  T visitBreak(BreakStatement node) => defaultNode(node);
  T visitContinue(ContinueStatement node) => defaultNode(node);
  T visitWith(WithStatement node) => defaultNode(node);
  T visitSwitch(SwitchStatement node) => defaultNode(node);
  T visitSwitchCase(SwitchCase node) => defaultNode(node);
  T visitReturn(ReturnStatement node) => defaultNode(node);
  T visitThrow(ThrowStatement node) => defaultNode(node);
  T visitTry(TryStatement node) => defaultNode(node);
  T visitCatchClause(CatchClause node) => defaultNode(node);
  T visitWhile(WhileStatement node) => defaultNode(node);
  T visitDoWhile(DoWhileStatement node) => defaultNode(node);
  T visitFor(ForStatement node) => defaultNode(node);
  T visitForIn(ForInStatement node) => defaultNode(node);
  T visitFunctionDeclaration(FunctionDeclaration node) => defaultNode(node);
  T visitVariableDeclaration(VariableDeclaration node) => defaultNode(node);
  T visitVariableDeclarator(VariableDeclarator node) => defaultNode(node);
  T visitDebugger(DebuggerStatement node) => defaultNode(node);

  T visitThis(ThisExpression node) => defaultNode(node);
  T visitArray(ArrayExpression node) => defaultNode(node);
  T visitObject(ObjectExpression node) => defaultNode(node);
  T visitProperty(Property node) => defaultNode(node);
  T visitFunctionExpression(FunctionExpression node) => defaultNode(node);
  T visitSequence(SequenceExpression node) => defaultNode(node);
  T visitUnary(UnaryExpression node) => defaultNode(node);
  T visitBinary(BinaryExpression node) => defaultNode(node);
  T visitAssignment(AssignmentExpression node) => defaultNode(node);
  T visitUpdateExpression(UpdateExpression node) => defaultNode(node);
  T visitConditional(ConditionalExpression node) => defaultNode(node);
  T visitCall(CallExpression node) => defaultNode(node);
  T visitMember(MemberExpression node) => defaultNode(node);
  T visitIndex(IndexExpression node) => defaultNode(node);
  T visitNameExpression(NameExpression node) => defaultNode(node);
  T visitLiteral(LiteralExpression node) => defaultNode(node);
  T visitRegexp(RegexpExpression node) => defaultNode(node);
}

/// Traverses the entire subtree when visiting a node.
///
/// When overriding a `visitXXX` method, it is your responsibility to visit
/// the children of the given node, otherwise that subtree will not be traversed.
///
/// For example:
///
///     visitWhile(While node) {
///         print('Found while loop on line ${node.line}');
///         node.forEach(visit); // visit children
///     }
///
/// Without the call to `forEach`, a while loop nested in another while loop would
/// not be found.
class RecursiveVisitor<T> extends BaseVisitor<T> {
  defaultNode(Node node) {
    node.forEach(visit);
  }
}

/// Visitor interface that takes an argument.
///
/// If multiple arguments are needed, they must be wrapped in a parameter object.
///
/// That there is no [RecursiveVisitor] variant that takes an argument.
/// For a generic traversal that takes arguments, consider using [BaseVisitor1] and
/// override `defaultNode` to visit the children of each node.
abstract class Visitor1<T, A> {
  /// Shorthand for `node.visitBy(this)`.
  T visit(Node node, A arg) => node.visitBy1(this, arg);

  T visitPrograms(Programs node, A arg);
  T visitProgram(Program node, A arg);
  T visitFunctionNode(FunctionNode node, A arg);
  T visitName(Name node, A arg);

  T visitEmptyStatement(EmptyStatement node, A arg);
  T visitBlock(BlockStatement node, A arg);
  T visitExpressionStatement(ExpressionStatement node, A arg);
  T visitIf(IfStatement node, A arg);
  T visitLabeledStatement(LabeledStatement node, A arg);
  T visitBreak(BreakStatement node, A arg);
  T visitContinue(ContinueStatement node, A arg);
  T visitWith(WithStatement node, A arg);
  T visitSwitch(SwitchStatement node, A arg);
  T visitSwitchCase(SwitchCase node, A arg);
  T visitReturn(ReturnStatement node, A arg);
  T visitThrow(ThrowStatement node, A arg);
  T visitTry(TryStatement node, A arg);
  T visitCatchClause(CatchClause node, A arg);
  T visitWhile(WhileStatement node, A arg);
  T visitDoWhile(DoWhileStatement node, A arg);
  T visitFor(ForStatement node, A arg);
  T visitForIn(ForInStatement node, A arg);
  T visitFunctionDeclaration(FunctionDeclaration node, A arg);
  T visitVariableDeclaration(VariableDeclaration node, A arg);
  T visitVariableDeclarator(VariableDeclarator node, A arg);
  T visitDebugger(DebuggerStatement node, A arg);

  T visitThis(ThisExpression node, A arg);
  T visitArray(ArrayExpression node, A arg);
  T visitObject(ObjectExpression node, A arg);
  T visitProperty(Property node, A arg);
  T visitFunctionExpression(FunctionExpression node, A arg);
  T visitSequence(SequenceExpression node, A arg);
  T visitUnary(UnaryExpression node, A arg);
  T visitBinary(BinaryExpression node, A arg);
  T visitAssignment(AssignmentExpression node, A arg);
  T visitUpdateExpression(UpdateExpression node, A arg);
  T visitConditional(ConditionalExpression node, A arg);
  T visitCall(CallExpression node, A arg);
  T visitMember(MemberExpression node, A arg);
  T visitIndex(IndexExpression node, A arg);
  T visitNameExpression(NameExpression node, A arg);
  T visitLiteral(LiteralExpression node, A arg);
  T visitRegexp(RegexpExpression node, A arg);
}

/// Implementation of [Visitor1] which redirects each `visit` method to a method [defaultNode].
///
/// This is convenient when only a couple of `visit` methods are needed
/// and a default action can be taken for all other nodes.
class BaseVisitor1<T, A> implements Visitor1<T, A> {
  T defaultNode(Node node, A arg) => null;

  T visit(Node node, A arg) => node.visitBy1(this, arg);

  T visitPrograms(Programs node, A arg) => defaultNode(node, arg);
  T visitProgram(Program node, A arg) => defaultNode(node, arg);
  T visitFunctionNode(FunctionNode node, A arg) => defaultNode(node, arg);
  T visitName(Name node, A arg) => defaultNode(node, arg);

  T visitEmptyStatement(EmptyStatement node, A arg) => defaultNode(node, arg);
  T visitBlock(BlockStatement node, A arg) => defaultNode(node, arg);
  T visitExpressionStatement(ExpressionStatement node, A arg) =>
      defaultNode(node, arg);
  T visitIf(IfStatement node, A arg) => defaultNode(node, arg);
  T visitLabeledStatement(LabeledStatement node, A arg) =>
      defaultNode(node, arg);
  T visitBreak(BreakStatement node, A arg) => defaultNode(node, arg);
  T visitContinue(ContinueStatement node, A arg) => defaultNode(node, arg);
  T visitWith(WithStatement node, A arg) => defaultNode(node, arg);
  T visitSwitch(SwitchStatement node, A arg) => defaultNode(node, arg);
  T visitSwitchCase(SwitchCase node, A arg) => defaultNode(node, arg);
  T visitReturn(ReturnStatement node, A arg) => defaultNode(node, arg);
  T visitThrow(ThrowStatement node, A arg) => defaultNode(node, arg);
  T visitTry(TryStatement node, A arg) => defaultNode(node, arg);
  T visitCatchClause(CatchClause node, A arg) => defaultNode(node, arg);
  T visitWhile(WhileStatement node, A arg) => defaultNode(node, arg);
  T visitDoWhile(DoWhileStatement node, A arg) => defaultNode(node, arg);
  T visitFor(ForStatement node, A arg) => defaultNode(node, arg);
  T visitForIn(ForInStatement node, A arg) => defaultNode(node, arg);
  T visitFunctionDeclaration(FunctionDeclaration node, A arg) =>
      defaultNode(node, arg);
  T visitVariableDeclaration(VariableDeclaration node, A arg) =>
      defaultNode(node, arg);
  T visitVariableDeclarator(VariableDeclarator node, A arg) =>
      defaultNode(node, arg);
  T visitDebugger(DebuggerStatement node, A arg) => defaultNode(node, arg);

  T visitThis(ThisExpression node, A arg) => defaultNode(node, arg);
  T visitArray(ArrayExpression node, A arg) => defaultNode(node, arg);
  T visitObject(ObjectExpression node, A arg) => defaultNode(node, arg);
  T visitProperty(Property node, A arg) => defaultNode(node, arg);
  T visitFunctionExpression(FunctionExpression node, A arg) =>
      defaultNode(node, arg);
  T visitSequence(SequenceExpression node, A arg) => defaultNode(node, arg);
  T visitUnary(UnaryExpression node, A arg) => defaultNode(node, arg);
  T visitBinary(BinaryExpression node, A arg) => defaultNode(node, arg);
  T visitAssignment(AssignmentExpression node, A arg) => defaultNode(node, arg);
  T visitUpdateExpression(UpdateExpression node, A arg) =>
      defaultNode(node, arg);
  T visitConditional(ConditionalExpression node, A arg) =>
      defaultNode(node, arg);
  T visitCall(CallExpression node, A arg) => defaultNode(node, arg);
  T visitMember(MemberExpression node, A arg) => defaultNode(node, arg);
  T visitIndex(IndexExpression node, A arg) => defaultNode(node, arg);
  T visitNameExpression(NameExpression node, A arg) => defaultNode(node, arg);
  T visitLiteral(LiteralExpression node, A arg) => defaultNode(node, arg);
  T visitRegexp(RegexpExpression node, A arg) => defaultNode(node, arg);
}
