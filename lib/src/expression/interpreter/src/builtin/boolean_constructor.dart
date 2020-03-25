import '../../interpreter.dart';

class JsBooleanConstructor extends JsConstructor {
  static JsBooleanConstructor singleton;

  factory JsBooleanConstructor(JsObject context) =>
      singleton ??= JsBooleanConstructor._(context);

  JsBooleanConstructor._(JsObject context) : super(context, constructor) {
    name = 'Boolean';
    prototype.addAll(<String, JsObject>{
      'constructor': this,
      'toString':
          wrapFunction(JsBooleanConstructor._toString, context, 'toString'),
      'valueOf':
          wrapFunction(JsBooleanConstructor._valueOf, context, 'valueOf'),
    });
  }

  static JsObject constructor(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    var first = arguments.getProperty(0.0, interpreter, ctx);

    if (first == null) {
      return JsBoolean(false);
    } else {
      return JsBoolean(first.isTruthy);
    }
  }

  static JsObject _toString(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    var v = ctx.scope.context;
    return coerceToBoolean(v, (b) {
      //print('WTF: ${b.valueOf} from ${v?.properties} (${v}) and ${arguments.valueOf}');
      return JsString(b.valueOf.toString());
    });
  }

  static JsObject _valueOf(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    return coerceToBoolean(ctx.scope.context, (b) => b);
  }
}
