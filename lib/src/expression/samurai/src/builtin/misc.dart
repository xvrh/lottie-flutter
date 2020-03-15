import '../../../parsejs/parsejs.dart';
import '../../samurai.dart';

void loadMiscObjects(Samurai samurai) {
  var global = samurai.global;

  var decodeUriFunction = JsFunction(global, (samurai, arguments, ctx) {
    try {
      return JsString(
          Uri.decodeFull(arguments.getProperty(0.0, samurai, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, samurai, ctx);
    }
  });

  var decodeUriComponentFunction =
      JsFunction(global, (samurai, arguments, ctx) {
    try {
      return JsString(Uri.decodeComponent(
          arguments.getProperty(0.0, samurai, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, samurai, ctx);
    }
  });
  var encodeUriFunction = JsFunction(global, (samurai, arguments, ctx) {
    try {
      return JsString(
          Uri.encodeFull(arguments.getProperty(0.0, samurai, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, samurai, ctx);
    }
  });

  var encodeUriComponentFunction =
      JsFunction(global, (samurai, arguments, ctx) {
    try {
      return JsString(Uri.encodeComponent(
          arguments.getProperty(0.0, samurai, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, samurai, ctx);
    }
  });

  var evalFunction = JsFunction(global, (samurai, arguments, ctx) {
    var src = arguments.getProperty(0.0, samurai, ctx)?.toString();
    if (src == null || src.trim().isEmpty) return null;

    try {
      var program = parsejs(src, filename: 'eval');
      return samurai.visitProgram(program, 'eval');
    } on ParseError catch (e) {
      throw ctx.callStack.error('Syntax', e.message);
    }
  });

  var isFinite = JsFunction(global, (samurai, arguments, ctx) {
    return JsBoolean(
        coerceToNumber(arguments.getProperty(0.0, samurai, ctx), samurai, ctx)
            .isFinite);
  });

  var isNaN = JsFunction(global, (samurai, arguments, ctx) {
    return JsBoolean(
        coerceToNumber(arguments.getProperty(0.0, samurai, ctx), samurai, ctx)
            .isNaN);
  });

  var parseFloatFunction = JsFunction(global, (samurai, arguments, ctx) {
    var str = arguments.getProperty(0.0, samurai, ctx)?.toString();
    var v = str == null ? null : double.tryParse(str);
    return v == null ? null : JsNumber(v);
  });

  var parseIntFunction = JsFunction(global, (samurai, arguments, ctx) {
    var str = arguments.getProperty(0.0, samurai, ctx)?.toString();
    var baseArg = arguments.getProperty(1.0, samurai, ctx);
    var base = baseArg == null ? 10 : int.tryParse(baseArg.toString());
    if (base == null) return JsNumber(double.nan);
    var v = str == null
        ? null
        : int.tryParse(str.replaceAll(RegExp(r'^0x'), ''), radix: base);
    return v == null ? JsNumber(double.nan) : JsNumber(v);
  });

  var printFunction = JsFunction(
    global,
    (samurai, arguments, scope) {
      arguments.valueOf.forEach(print);
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
