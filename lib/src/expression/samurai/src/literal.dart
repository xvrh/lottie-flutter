import 'object.dart';

class JsBoolean extends JsObject {
  final bool valueOf;

  JsBoolean(this.valueOf) {
    typeof = 'boolean';
  }

  @override
  bool get isTruthy => valueOf;

  @override
  String toString() => valueOf.toString();
}

// TODO: Prototype???
class JsString extends JsObject {
  final String valueOf;

  JsString(this.valueOf) {
    typeof = 'string';
  }

  @override
  bool get isTruthy => valueOf.isNotEmpty;

  @override
  String toString() => valueOf;
}

// TODO: Prototype???
class JsNumber extends JsObject {
  final num _valueOf;

  JsNumber(this._valueOf) {
    typeof = 'number';
  }

  double get valueOf => _valueOf.toDouble();

  @override
  bool get isTruthy => valueOf != 0.0;

  @override
  String toString() {
    if (valueOf.isNaN) {
      return 'NaN';
    } else if (valueOf.isInfinite) {
      return valueOf.isNegative ? '-Infinity' : 'Infinity';
    } else {
      return (valueOf == valueOf.toInt())
          ? valueOf.toInt().toString()
          : valueOf.toString();
    }
  }
}

class JsNull extends JsObject {
  @override
  Null get valueOf => null;

  @override
  bool get isTruthy => false;

  @override
  String toString() => 'null';
}
