import 'literal.dart';
import 'object.dart';

class JsArguments extends JsObject {
  @override
  final List<JsObject> valueOf;
  final JsObject callee;

  JsArguments(this.valueOf, this.callee) {
    properties['callee'] = properties['caller'] = callee;
    properties['length'] = new JsNumber(valueOf.length);

    for (int i = 0; i < valueOf.length; i++) {
      properties[i.toDouble()] = valueOf[i];
    }
  }

  @override
  String toString() {
    if (valueOf.isEmpty) {
      return '';
    } else if (valueOf.length == 1) {
      return valueOf[0].toString();
    } else {
      return valueOf.map((x) => x.toString()).join(',');
    }
  }
}
