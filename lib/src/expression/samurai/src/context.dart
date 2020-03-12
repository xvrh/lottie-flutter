import '../../symbol_table/symbol_table.dart';
import 'object.dart';
import 'stack.dart';

class SamuraiContext {
  final SymbolTable<JsObject> scope;
  final CallStack callStack;

  SamuraiContext(this.scope, this.callStack);

  SamuraiContext createChild() {
    return new SamuraiContext(scope.createChild(), callStack.duplicate());
  }

  SamuraiContext bind(JsObject context) {
    return createChild()..scope.context = context;
  }
}
