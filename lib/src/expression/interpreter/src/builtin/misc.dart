import '../../../parsejs/parsejs.dart';
import '../../interpreter.dart';

void loadMiscObjects(Interpreter interpreter) {
  var global = interpreter.global;

  var decodeUriFunction = JsFunction(global, (interpreter, arguments, ctx) {
    try {
      return JsString(Uri.decodeFull(
          arguments.getProperty(0.0, interpreter, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, interpreter, ctx);
    }
  });

  var decodeUriComponentFunction =
      JsFunction(global, (interpreter, arguments, ctx) {
    try {
      return JsString(Uri.decodeComponent(
          arguments.getProperty(0.0, interpreter, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, interpreter, ctx);
    }
  });
  var encodeUriFunction = JsFunction(global, (interpreter, arguments, ctx) {
    try {
      return JsString(Uri.encodeFull(
          arguments.getProperty(0.0, interpreter, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, interpreter, ctx);
    }
  });

  var encodeUriComponentFunction =
      JsFunction(global, (interpreter, arguments, ctx) {
    try {
      return JsString(Uri.encodeComponent(
          arguments.getProperty(0.0, interpreter, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, interpreter, ctx);
    }
  });

  var evalFunction = JsFunction(global, (interpreter, arguments, ctx) {
    var src = arguments.getProperty(0.0, interpreter, ctx)?.toString();
    if (src == null || src.trim().isEmpty) return null;

    try {
      var program = parsejs(src, filename: 'eval');
      return interpreter.visitProgram(program, 'eval');
    } on ParseError catch (e) {
      throw ctx.callStack.error('Syntax', e.message);
    }
  });

  var isFinite = JsFunction(global, (interpreter, arguments, ctx) {
    return JsBoolean(coerceToNumber(
            arguments.getProperty(0.0, interpreter, ctx), interpreter, ctx)
        .isFinite);
  });

  var isNaN = JsFunction(global, (interpreter, arguments, ctx) {
    return JsBoolean(coerceToNumber(
            arguments.getProperty(0.0, interpreter, ctx), interpreter, ctx)
        .isNaN);
  });

  var parseFloatFunction = JsFunction(global, (interpreter, arguments, ctx) {
    var str = arguments.getProperty(0.0, interpreter, ctx)?.toString();
    var v = str == null ? null : double.tryParse(str);
    return v == null ? null : JsNumber(v);
  });

  var parseIntFunction = JsFunction(global, (interpreter, arguments, ctx) {
    var str = arguments.getProperty(0.0, interpreter, ctx)?.toString();
    var baseArg = arguments.getProperty(1.0, interpreter, ctx);
    var base = baseArg == null ? 10 : int.tryParse(baseArg.toString());
    if (base == null) return JsNumber(double.nan);
    var v = str == null
        ? null
        : int.tryParse(str.replaceAll(RegExp(r'^0x'), ''), radix: base);
    return v == null ? JsNumber(double.nan) : JsNumber(v);
  });

  var printFunction = JsFunction(
    global,
    (interpreter, arguments, scope) {
      arguments.valueOf.forEach(print);
      return JsNull();
    },
  );

  global.properties.addAll(<String, JsObject>{
    'decodeURI': decodeUriFunction..name = 'decodeURI',
    'decodeURIComponent': decodeUriComponentFunction
      ..name = 'decodeURIComponent',
    'encodeURI': encodeUriFunction..name = 'encodeURI',
    'encodeURIComponent': encodeUriComponentFunction
      ..name = 'encodeURIComponent',
    'eval': evalFunction..name = 'eval',
    'Infinity': JsNumber(double.infinity),
    'isFinite': isFinite..name = 'isFinite',
    'isNaN': isNaN..name = 'isNaN',
    'NaN': JsNumber(double.nan),
    'parseFloat': parseFloatFunction..name = 'parseFloat',
    'parseInt': parseIntFunction..name = 'parseInt',
    'print': printFunction..properties['name'] = JsString('print'),
  });
}
