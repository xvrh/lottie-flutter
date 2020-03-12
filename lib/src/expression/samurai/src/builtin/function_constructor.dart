import '../../../parsejs/parsejs.dart';
import '../../samurai.dart';

class JsFunctionConstructor extends JsConstructor {
  static JsFunctionConstructor singleton;

  factory JsFunctionConstructor(JsObject context) =>
      singleton ??= new JsFunctionConstructor._(context);

  JsFunctionConstructor._(JsObject context) : super(context, constructor) {
    name = 'Function';
    prototype.addAll(<String, JsObject>{
      'constructor': this,
      'apply': wrapFunction(JsFunctionConstructor.apply, context, 'apply'),
      'bind': wrapFunction(JsFunctionConstructor.bind_, context, 'bind'),
      'call': wrapFunction(JsFunctionConstructor.call_, context, 'call'),
    });
  }

  static JsObject constructor(
      Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    List<String> paramNames;
    Program body;

    if (arguments.valueOf.isEmpty) {
      paramNames = <String>[];
    } else {
      paramNames = arguments.valueOf.length <= 1
          ? <String>[]
          : arguments.valueOf
              .take(arguments.valueOf.length - 1)
              .map((o) => coerceToString(o, samurai, ctx))
              .toList();
      body = parsejs(arguments.valueOf.isEmpty
          ? ''
          : coerceToString(arguments.valueOf.last, samurai, ctx));
    }

    var f = new JsFunction(ctx.scope.context, (samurai, arguments, ctx) {
      ctx = ctx.createChild();

      for (int i = 0; i < paramNames.length; i++) {
        ctx.scope.create(
          paramNames[i],
          value: arguments.getProperty(i.toDouble(), samurai, ctx),
        );
      }

      return body == null
          ? null
          : samurai.visitProgram(body, 'anonymous function', ctx);
    });

    f.closureScope = samurai.globalScope.createChild()
      ..context = samurai
          .global; // Yes, this is the intended semantics. Operates in the global scope.
    return f;
  }

  static JsObject apply(
      Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    return coerceToFunction(arguments.getProperty(0.0, samurai, ctx), (f) {
      var a1 = arguments.getProperty(1.0, samurai, ctx);
      var args = a1 is JsArray ? a1.valueOf : <JsObject>[];
      return samurai.invoke(f, args, ctx);
    });
  }

  static JsObject bind_(
      Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    return coerceToFunction(
        arguments.getProperty(0.0, samurai, ctx),
        (f) => f.bind(
            arguments.getProperty(1.0, samurai, ctx) ?? ctx.scope.context));
  }

  static JsObject call_(
      Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    return coerceToFunction(arguments.getProperty(0.0, samurai, ctx), (f) {
      return samurai.invoke(f, arguments.valueOf.skip(1).toList(), ctx);
    });
  }
}
