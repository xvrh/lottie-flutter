import 'context.dart';
import 'literal.dart';
import 'object.dart';
import 'samurai.dart';
import 'util.dart';

class JsArray extends JsObject {
  final List<JsObject> valueOf = [];

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
  JsObject getProperty(dynamic name, Samurai samurai, SamuraiContext ctx) {
    if (name is num) {
      // TODO: RangeError?
      var v = valueOf[name.toInt()];
      return v is JsEmptyItem ? null : v;
    } else {
      return super.getProperty(name, samurai, ctx);
    }
  }

  @override
  bool removeProperty(dynamic name, Samurai samurai, SamuraiContext ctx) {
    if (name is String) {
      return removeProperty(
          coerceToNumber(new JsString(name), samurai, ctx), samurai, ctx);
    } else if (name is num && name.isFinite) {
      var i = name.toInt();
      if (i >= 0 && i < valueOf.length) {
        valueOf[i] = new JsEmptyItem();
      }
      return true;
    } else {
      return super.removeProperty(name, samurai, ctx);
    }
  }

  // TODO: Set property for index..?
}

class JsEmptyItem extends JsObject {
  @override
  String toString() => '';
}
