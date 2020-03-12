import 'array.dart';
import 'context.dart';
import 'function.dart';
import 'literal.dart';
import 'object.dart';
import 'samurai.dart';

bool canCoerceToNumber(JsObject object) {
  return object is JsNumber ||
      object is JsBoolean ||
      object is JsNull ||
      object == null ||
      (object is JsArray && object.valueOf.length != 1) ||
      object.properties.containsKey('valueOf');
}

double coerceToNumber(JsObject object, Samurai samurai, SamuraiContext ctx) {
  if (object is JsNumber) {
    return object.valueOf;
  } else if (object == null) {
    return double.nan;
  } else if (object is JsNull) {
    return 0.0;
  } else if (object is JsBoolean) {
    return object.valueOf ? 1.0 : 0.0;
  } else if (object is JsArray && object.valueOf.isEmpty) {
    return 0.0;
  } else if (object is JsString) {
    return num.tryParse(object.valueOf)?.toDouble() ?? double.nan;
  } else {
    var valueOfFunc = object?.getProperty('valueOf', samurai, ctx);

    if (valueOfFunc != null) {
      if (valueOfFunc is JsFunction) {
        return coerceToNumber(
            samurai.invoke(valueOfFunc, [], ctx), samurai, ctx);
      }

      return double.nan;
    } else {
      return double.nan;
    }
  }
}

String coerceToString(JsObject object, Samurai samurai, SamuraiContext ctx) {
  if (object == null) {
    return 'undefined';
  } else {
    return object.toString();
  }
}

JsObject coerceToFunction(JsObject obj, JsObject Function(JsFunction) f) {
  if (obj is! JsFunction) {
    return null;
  } else {
    return f(obj as JsFunction);
  }
}

JsObject coerceToBoolean(JsObject obj, JsObject Function(JsBoolean) f) {
  if (obj is! JsBoolean) {
    return f(new JsBoolean(obj?.isTruthy ?? false));
  } else {
    return f(obj as JsBoolean);
  }
}

JsBoolean safeBooleanOperation(JsObject left, JsObject right, Samurai samurai,
    SamuraiContext ctx, bool Function(num, num) f) {
  var l = coerceToNumber(left, samurai, ctx);
  var r = coerceToNumber(right, samurai, ctx);

  if (l.isNaN || r.isNaN) {
    return new JsBoolean(false);
  } else {
    return new JsBoolean(f(l, r));
  }
}

JsFunction wrapFunction(JsFunctionCallback f, JsObject context, [String name]) {
  return new JsFunction(context, f)..name = name;
}
