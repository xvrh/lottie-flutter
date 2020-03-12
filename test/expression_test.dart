import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/expression/parsejs/parsejs.dart';
import 'package:lottie/src/expression/samurai/samurai.dart';

void main() {
  test('Expressions', () {
    var expressions = <String>[
      r'''
var $bm_rt;
var amp, freq, decay, n, n, t, t, v;
amp = 0.1;
freq = 1.5;
decay = 4;
$bm_rt = n = 0;
if (numKeys > 0) {
    $bm_rt = n = nearestKey(time).index;
    if (key(n).time > time) {
        n--;
    }
}
if (n == 0) {
    $bm_rt = t = 0;
} else {
    $bm_rt = t = sub(time, key(n).time);
}
if (n > 0) {
    v = velocityAtTime(sub(key(n).time, div(thisComp.frameDuration, 10)));
    $bm_rt = sum(value, div(mul(mul(v, amp), Math.sin(mul(mul(mul(freq, t), 2), Math.PI))), Math.exp(mul(decay, t))));
} else {
    $bm_rt = value;
}
      ''',
    ];

    for (var expression in expressions) {
      var parsed = parsejs(expression);
      print(parsed);

      var interpreter = Samurai();
      interpreter
        ..global.properties['nearestKey'] =
            JsFunction(interpreter.global, (samurai, arguments, ctx) {
          var object = JsObject();
          object.properties['index'] = JsNumber(0);
          return object;
        })
        ..global.properties['key'] =
            JsFunction(interpreter.global, (samurai, arguments, ctx) {
          var object = JsObject();
          object.properties['time'] = JsNumber(0);
          return object;
        })
        ..global.properties['sub'] =
            JsFunction(interpreter.global, (samurai, arguments, ctx) {
          var object = JsObject();
          return object;
        })
        ..global.properties['time'] = JsNumber(100)
        ..global.properties['value'] = JsNumber(100)
        ..globalScope.create('numKeys', value: JsNumber(3));

      interpreter.visitProgram(parsed);
    }
  });
}
