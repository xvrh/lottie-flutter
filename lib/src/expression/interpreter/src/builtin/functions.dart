import '../../interpreter.dart';
import 'boolean_constructor.dart';
import 'function_constructor.dart';
import 'misc.dart';

void loadBuiltinObjects(Interpreter interpreter) {
  loadMiscObjects(interpreter);

  interpreter.global.properties.addAll(<String, JsObject>{
    'Boolean': JsBooleanConstructor(interpreter.global),
    'Function': JsFunctionConstructor(interpreter.global),
  });
}
