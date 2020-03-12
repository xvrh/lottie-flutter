import '../../../parsejs/parsejs.dart';
import '../../samurai.dart';

void loadMiscObjects(Samurai samurai) {
  var global = samurai.global;

  var decodeUriFunction = new JsFunction(global, (samurai, arguments, ctx) {
    try {
      return new JsString(
          Uri.decodeFull(arguments.getProperty(0.0, samurai, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, samurai, ctx);
    }
  });

  var decodeUriComponentFunction =
      new JsFunction(global, (samurai, arguments, ctx) {
    try {
      return new JsString(Uri.decodeComponent(
          arguments.getProperty(0.0, samurai, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, samurai, ctx);
    }
  });
  var encodeUriFunction = new JsFunction(global, (samurai, arguments, ctx) {
    try {
      return new JsString(
          Uri.encodeFull(arguments.getProperty(0.0, samurai, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, samurai, ctx);
    }
  });

  var encodeUriComponentFunction =
      new JsFunction(global, (samurai, arguments, ctx) {
    try {
      return new JsString(Uri.encodeComponent(
          arguments.getProperty(0.0, samurai, ctx)?.toString()));
    } catch (_) {
      return arguments.getProperty(0.0, samurai, ctx);
    }
  });

  var evalFunction = new JsFunction(global, (samurai, arguments, ctx) {
    var src = arguments.getProperty(0.0, samurai, ctx)?.toString();
    if (src == null || src.trim().isEmpty) return null;

    try {
      var program = parsejs(src, filename: 'eval');
      return samurai.visitProgram(program, 'eval');
    } on ParseError catch (e) {
      throw ctx.callStack.error('Syntax', e.message);
    }
  });

  var isFinite = new JsFunction(global, (samurai, arguments, ctx) {
    return new JsBoolean(
        coerceToNumber(arguments.getProperty(0.0, samurai, ctx), samurai, ctx)
            .isFinite);
  });

  var isNaN = new JsFunction(global, (samurai, arguments, ctx) {
    return new JsBoolean(
        coerceToNumber(arguments.getProperty(0.0, samurai, ctx), samurai, ctx)
            .isNaN);
  });

  var parseFloatFunction = new JsFunction(global, (samurai, arguments, ctx) {
    var str = arguments.getProperty(0.0, samurai, ctx)?.toString();
    var v = str == null ? null : double.tryParse(str);
    return v == null ? null : new JsNumber(v);
  });

  var parseIntFunction = new JsFunction(global, (samurai, arguments, ctx) {
    var str = arguments.getProperty(0.0, samurai, ctx)?.toString();
    var baseArg = arguments.getProperty(1.0, samurai, ctx);
    var base = baseArg == null ? 10 : int.tryParse(baseArg.toString());
    if (base == null) return new JsNumber(double.nan);
    var v = str == null
        ? null
        : int.tryParse(str.replaceAll(new RegExp(r'^0x'), ''), radix: base);
    return v == null ? new JsNumber(double.nan) : new JsNumber(v);
  });

  var printFunction = new JsFunction(
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
    'Infinity': new JsNumber(double.infinity),
    'isFinite': isFinite..name = 'isFinite',
    'isNaN': isNaN..name = 'isNaN',
    'NaN': new JsNumber(double.nan),
    'parseFloat': parseFloatFunction..name = 'parseFloat',
    'parseInt': parseIntFunction..name = 'parseInt',
    'print': printFunction..properties['name'] = new JsString('print'),
  });
}
