library scope;

import 'ast.dart';

void annotateAST(Program ast) {
  setParentPointers(ast);
  new EnvironmentBuilder()..build(ast);
  new Resolver()..resolve(ast);
}

void setParentPointers(Node node, [Node parent]) {
  node.parent = parent;
  node.forEach((child) => setParentPointers(child, node));
}

/// Initializes [Scope.environment] for all scopes in a given AST.
class EnvironmentBuilder extends RecursiveVisitor<Null> {
  void build(Program ast) {
    visit(ast);
  }

  Scope currentScope; // Program or FunctionExpression

  void addVar(Name name) {
    currentScope.environment.add(name.value);
  }

  visitProgram(Program node) {
    node.environment = new Set<String>();
    currentScope = node;
    node.forEach(visit);
  }

  visitFunctionNode(FunctionNode node) {
    node.environment = new Set<String>();
    Scope oldScope = currentScope;
    currentScope = node;
    node.environment.add('arguments');
    if (node.isExpression && node.name != null) {
      addVar(node.name);
    }
    node.params.forEach(addVar);
    visit(node.body);
    currentScope = oldScope;
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    addVar(node.function.name);
    visit(node.function);
  }

  visitFunctionExpression(FunctionExpression node) {
    visit(node.function);
  }

  visitVariableDeclarator(VariableDeclarator node) {
    addVar(node.name);
    node.forEach(visit);
  }

  visitCatchClause(CatchClause node) {
    node.environment = new Set<String>();
    node.environment.add(node.param.value);
    node.forEach(visit);
  }
}

/// Initializes the [Name.scope] link on all [Name] nodes.
class Resolver extends RecursiveVisitor<Null> {
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
    String name = nameNode.value;
    Node parent = nameNode.parent;
    Node node = nameNode;
    if (parent is FunctionNode && parent.name == node && !parent.isExpression) {
      node = parent.parent;
    }
    Scope scope = enclosingScope(node);
    while (scope is! Program) {
      if (scope.environment == null)
        throw "$scope does not have an environment";
      if (scope.environment.contains(name)) return scope;
      scope = enclosingScope(scope.parent);
    }
    return scope;
  }

  visitName(Name name) {
    if (name.isVariable) {
      name.scope = findScope(name);
    }
  }
}
