import '../../../parsejs/parsejs.dart';
import '../../interpreter.dart';

class JsFunctionConstructor extends JsConstructor {
  static JsFunctionConstructor singleton;

  factory JsFunctionConstructor(JsObject context) =>
      singleton ??= JsFunctionConstructor._(context);

  JsFunctionConstructor._(JsObject context) : super(context, constructor) {
    name = 'Function';
    prototype.addAll(<String, JsObject>{
      'constructor': this,
      'apply': wrapFunction(JsFunctionConstructor.apply, context, 'apply'),
      'bind': wrapFunction(JsFunctionConstructor._bind, context, 'bind'),
      'call': wrapFunction(JsFunctionConstructor._call, context, 'call'),
    });
  }

  static JsObject constructor(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    List<String> paramNames;
    Program body;

    if (arguments.valueOf.isEmpty) {
      paramNames = <String>[];
    } else {
      paramNames = arguments.valueOf.length <= 1
          ? <String>[]
          : arguments.valueOf
              .take(arguments.valueOf.length - 1)
              .map((o) => coerceToString(o, interpreter, ctx))
              .toList();
      body = parsejs(arguments.valueOf.isEmpty
          ? ''
          : coerceToString(arguments.valueOf.last, interpreter, ctx));
    }

    var f = JsFunction(ctx.scope.context, (interpreter, arguments, ctx) {
      ctx = ctx.createChild();

      for (var i = 0; i < paramNames.length; i++) {
        ctx.scope.create(
          paramNames[i],
          value: arguments.getProperty(i.toDouble(), interpreter, ctx),
        );
      }

      return body == null
          ? null
          : interpreter.visitProgram(body, 'anonymous function', ctx);
    });

    f.closureScope = interpreter.globalScope.createChild()
      ..context = interpreter
          .global; // Yes, this is the intended semantics. Operates in the global scope.
    return f;
  }

  static JsObject apply(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    return coerceToFunction(arguments.getProperty(0.0, interpreter, ctx), (f) {
      var a1 = arguments.getProperty(1.0, interpreter, ctx);
      var args = a1 is JsArray ? a1.valueOf : <JsObject>[];
      return interpreter.invoke(f, args, ctx);
    });
  }

  static JsObject _bind(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    return coerceToFunction(
        arguments.getProperty(0.0, interpreter, ctx),
        (f) => f.bind(
            arguments.getProperty(1.0, interpreter, ctx) ?? ctx.scope.context));
  }

  static JsObject _call(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    return coerceToFunction(arguments.getProperty(0.0, interpreter, ctx), (f) {
      return interpreter.invoke(f, arguments.valueOf.skip(1).toList(), ctx);
    });
  }
}
