import '../../samurai.dart';
import 'boolean_constructor.dart';
import 'function_constructor.dart';
import 'misc.dart';

void loadBuiltinObjects(Samurai samurai) {
  loadMiscObjects(samurai);

  samurai.global.properties.addAll(<String, JsObject>{
    'Boolean': JsBooleanConstructor(samurai.global),
    'Function': JsFunctionConstructor(samurai.global),
  });
}
