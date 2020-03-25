import '../../parsejs/parsejs.dart';
import '../interpreter.dart';
import '../../symbol_table/symbol_table.dart';

/// The Dart function that is responsible for the logic of a given [JsFunction].
typedef JsFunctionCallback = JsObject Function(
    Interpreter interpreter, JsArguments arguments, InterpreterContext ctx);

class JsFunction extends JsObject {
  final JsObject Function(Interpreter, JsArguments, InterpreterContext) f;
  final JsObject context;
  SymbolTable<JsObject> closureScope;
  Node declaration;

  JsFunction(this.context, this.f) {
    typeof = 'function';
    properties['length'] = JsNumber(0);
    properties['name'] = JsString('anonymous');
    properties['prototype'] = JsObject();
  }

  bool get isAnonymous {
    return properties['name'] == null ||
        properties['name'].toString() == 'anonymous';
  }

  String get name {
    if (isAnonymous) {
      return '(anonymous function)';
    } else {
      return properties['name'].toString();
    }
  }

  set name(String value) => properties['name'] = JsString(value);

  @override
  JsObject getProperty(
      dynamic name, Interpreter interpreter, InterpreterContext ctx) {
    if (name is JsString) {
      return getProperty(name.valueOf, interpreter, ctx);
    } else if (name == 'apply') {
      return wrapFunction((interpreter, arguments, ctx) {
        var a1 = arguments.getProperty(1.0, interpreter, ctx);
        var args = a1 is JsArray ? a1.valueOf : <JsObject>[];
        return interpreter.invoke(this, args,
            arguments.valueOf.isEmpty ? ctx : ctx.bind(arguments.valueOf[0]));
      }, this, 'call');
    } else if (name == 'bind') {
      return wrapFunction(
          (_, arguments, ctx) => bind(
              arguments.getProperty(0.0, interpreter, ctx) ??
                  ctx.scope.context),
          this,
          'bind');
    } else if (name == 'call') {
      return wrapFunction((interpreter, arguments, ctx) {
        var thisCtx = arguments.getProperty(0.0, interpreter, ctx) ??
            ((arguments.valueOf.isNotEmpty ? arguments.valueOf[0] : null) ??
                ctx.scope.context);
        return interpreter.invoke(bind(thisCtx),
            arguments.valueOf.skip(1).toList(), ctx.bind(thisCtx));
      }, this, 'call');
    } else if (name == 'constructor') {
      return JsFunctionConstructor.singleton;
    } else {
      return super.getProperty(name, interpreter, ctx);
    }
  }

  JsFunction bind(JsObject newContext) {
    if (newContext == null) return bind(JsNull());

    var ff = JsFunction(newContext, f)
      ..properties.addAll(properties)
      ..closureScope = closureScope?.fork()
      ..declaration = declaration;

    if (isAnonymous || name == null) {
      ff.name = 'bound ';
    } else {
      ff.name = 'bound $name';
    }

    return ff;
  }

  @override
  String toString() {
    return isAnonymous ? '[Function]' : '[Function: $name]';
  }
}

class JsConstructor extends JsFunction {
  JsConstructor(JsObject context,
      JsObject Function(Interpreter, JsArguments, InterpreterContext) f)
      : super(context, f);
}
