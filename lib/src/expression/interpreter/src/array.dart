import 'context.dart';
import 'literal.dart';
import 'object.dart';
import 'interpreter.dart';
import 'util.dart';

class JsArray extends JsObject {
  @override
  final List<JsObject> valueOf = <JsObject>[];

  JsArray() {
    typeof = 'array';
  }

  // TODO: Set index???
  // TODO: Value of

  @override
  String toString() {
    if (valueOf.isEmpty) {
      return '';
    } else if (valueOf.length == 1) {
      return valueOf[0].toString();
    } else {
      return valueOf.map((x) => x?.toString() ?? 'undefined').join(',');
    }
  }

  @override
  JsObject getProperty(
      dynamic name, Interpreter interpreter, InterpreterContext ctx) {
    if (name is num) {
      // TODO: RangeError?
      var v = valueOf[name.toInt()];
      return v is JsEmptyItem ? null : v;
    } else {
      return super.getProperty(name, interpreter, ctx);
    }
  }

  @override
  bool removeProperty(
      dynamic name, Interpreter interpreter, InterpreterContext ctx) {
    if (name is String) {
      return removeProperty(
          coerceToNumber(JsString(name), interpreter, ctx), interpreter, ctx);
    } else if (name is num && name.isFinite) {
      var i = name.toInt();
      if (i >= 0 && i < valueOf.length) {
        valueOf[i] = JsEmptyItem();
      }
      return true;
    } else {
      return super.removeProperty(name, interpreter, ctx);
    }
  }

  // TODO: Set property for index..?
}

class JsEmptyItem extends JsObject {
  @override
  String toString() => '';
}
