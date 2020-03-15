library scope;

import 'ast.dart';

void annotateAST(Program ast) {
  setParentPointers(ast);
  EnvironmentBuilder()..build(ast);
  Resolver()..resolve(ast);
}

void setParentPointers(Node node, [Node parent]) {
  node.parent = parent;
  node.forEach((child) => setParentPointers(child, node));
}

/// Initializes [Scope.environment] for all scopes in a given AST.
class EnvironmentBuilder extends RecursiveVisitor<void> {
  void build(Program ast) {
    visit(ast);
  }

  Scope currentScope; // Program or FunctionExpression

  void addVar(Name name) {
    currentScope.environment.add(name.value);
  }

  @override
  void visitProgram(Program node) {
    node.environment = <String>{};
    currentScope = node;
    node.forEach(visit);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    node.environment = <String>{};
    var oldScope = currentScope;
    currentScope = node;
    node.environment.add('arguments');
    if (node.isExpression && node.name != null) {
      addVar(node.name);
    }
    node.params.forEach(addVar);
    visit(node.body);
    currentScope = oldScope;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    addVar(node.function.name);
    visit(node.function);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    visit(node.function);
  }

  @override
  void visitVariableDeclarator(VariableDeclarator node) {
    addVar(node.name);
    node.forEach(visit);
  }

  @override
  void visitCatchClause(CatchClause node) {
    node.environment = <String>{};
    node.environment.add(node.param.value);
    node.forEach(visit);
  }
}

/// Initializes the [Name.scope] link on all [Name] nodes.
class Resolver extends RecursiveVisitor<void> {
  void resolve(Program ast) {
    visit(ast);
  }

  Scope enclosingScope(Node node) {
    while (node is! Scope) {
      node = node.parent;
    }
    return node as Scope;
  }

  Scope findScope(Name nameNode) {
    var name = nameNode.value;
    var parent = nameNode.parent;
    Node node = nameNode;
    if (parent is FunctionNode && parent.name == node && !parent.isExpression) {
      node = parent.parent;
    }
    var scope = enclosingScope(node);
    while (scope is! Program) {
      if (scope.environment == null) {
        throw Exception('$scope does not have an environment');
      }
      if (scope.environment.contains(name)) return scope;
      scope = enclosingScope(scope.parent);
    }
    return scope;
  }

  @override
  void visitName(Name node) {
    if (node.isVariable) {
      node.scope = findScope(node);
    }
  }
}
