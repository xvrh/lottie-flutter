import 'context.dart';
import 'function.dart';
import 'literal.dart';
import 'samurai.dart';
import 'util.dart';

class JsObject {
  final properties = <dynamic, JsObject>{};

  //final Map<String, JsObject> prototype = {};
  String typeof = 'object';

  bool get isTruthy => true;

  dynamic get valueOf => properties;

  JsObject get jsValueOf => this;

  bool isLooselyEqualTo(JsObject other) {
    // TODO: Finish this stupidity
    return false;
  }

  dynamic coerceIndex(dynamic name) {
    if (name is JsNumber) {
      return name.toString();
    } else if (name is JsString) {
      return name.toString();
    } else {
      return name;
    }
  }

  JsObject getProperty(dynamic name, Samurai samurai, SamuraiContext ctx) {
    name = coerceIndex(name);

    if (name == 'valueOf') {
      return properties['valueOf'] ??
          wrapFunction(
              (_, __, _____) => jsValueOf, ctx.scope.context, 'valueOf');
    }

//    if (name == 'prototype') {
//      return new JsPrototype(prototype);
//    } else {
    return properties[name];
//    }
  }

  bool removeProperty(dynamic name, Samurai samurai, SamuraiContext ctx) {
    name = coerceIndex(name);
    properties.remove(name);
    return true;
    /*
    if (name is JsObject) {
      return removeProperty(coerceToString(name, samurai, ctx), samurai, ctx);
    } else if (name is String) {
    } else {
      properties.remove(name);
      return true;
    }
    */
  }

  Map<dynamic, JsObject> get prototype {
    return (properties['prototype'] ??= new JsObject()).properties;
  }

  JsObject newInstance() {
    var obj = new JsObject();
    var p = prototype;

    for (var key in p.keys) {
      var value = p[key];

      if (value is JsFunction) {
        obj.properties[key] = value.bind(obj);
      } else {
        obj.properties[key] = value;
      }
    }

    return obj;
  }

  @override
  String toString() => '[object Object]';

  JsObject setProperty(dynamic name, JsObject value) {
    return properties[coerceIndex(name)] = value;
  }
}

class JsBuiltinObject extends JsObject {}

class JsPrototype extends JsObject {
  @override
  final Map<String, JsObject> properties;

  JsPrototype(this.properties);
}
