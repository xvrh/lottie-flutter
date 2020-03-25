import '../../symbol_table/symbol_table.dart';
import 'object.dart';
import 'stack.dart';

class InterpreterContext {
  final SymbolTable<JsObject> scope;
  final CallStack callStack;

  InterpreterContext(this.scope, this.callStack);

  InterpreterContext createChild() {
    return InterpreterContext(scope.createChild(), callStack.duplicate());
  }

  InterpreterContext bind(JsObject context) {
    return createChild()..scope.context = context;
  }
}
