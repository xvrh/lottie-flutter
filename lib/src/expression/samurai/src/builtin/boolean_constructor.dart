import '../../samurai.dart';

class JsBooleanConstructor extends JsConstructor {
  static JsBooleanConstructor singleton;

  factory JsBooleanConstructor(JsObject context) =>
      singleton ??= new JsBooleanConstructor._(context);

  JsBooleanConstructor._(JsObject context) : super(context, constructor) {
    name = 'Boolean';
    prototype.addAll(<String, JsObject>{
      'constructor': this,
      'toString':
          wrapFunction(JsBooleanConstructor.toString_, context, 'toString'),
      'valueOf':
          wrapFunction(JsBooleanConstructor.valueOf_, context, 'valueOf'),
    });
  }

  static JsObject constructor(
      Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    var first = arguments.getProperty(0.0, samurai, ctx);

    if (first == null) {
      return new JsBoolean(false);
    } else {
      return new JsBoolean(first.isTruthy);
    }
  }

  static JsObject toString_(
      Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    var v = ctx.scope.context;
    return coerceToBoolean(v, (b) {
      //print('WTF: ${b.valueOf} from ${v?.properties} (${v}) and ${arguments.valueOf}');
      return new JsString(b.valueOf.toString());
    });
  }

  static JsObject valueOf_(
      Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    return coerceToBoolean(ctx.scope.context, (b) => b);
  }
}
