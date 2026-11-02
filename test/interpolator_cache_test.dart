import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

// One layer whose opacity goes from 0 to 100 over 10 frames with the given
// easing (out tangent, in tangent).
LottieComposition _fade(List<num> out, List<num> into) {
  var json = {
    'v': '5.7.0',
    'fr': 10,
    'ip': 0,
    'op': 10,
    'w': 10,
    'h': 10,
    'layers': [
      {
        'ty': 3,
        'ind': 1,
        'ip': 0,
        'op': 10,
        'st': 0,
        'ks': {
          'o': {
            'a': 1,
            'k': [
              {
                't': 0,
                's': [0],
                'e': [100],
                'o': {
                  'x': [out[0]],
                  'y': [out[1]],
                },
                'i': {
                  'x': [into[0]],
                  'y': [into[1]],
                },
              },
              {
                't': 10,
                's': [100],
              },
            ],
          },
        },
      },
    ],
  };
  return LottieComposition.parseJsonBytes(utf8.encode(jsonEncode(json)));
}

// The eased value of the first opacity keyframe at 25% of its duration.
double _easedAtQuarter(LottieComposition composition) {
  var keyframe = composition.layers.first.transform.opacity!.keyframes.first;
  return keyframe.interpolator!.transform(0.25);
}

void main() {
  // The interpolator cache was keyed by Utils.hashFor, which skips the zero
  // components, so (0, 0, 1, 1) and (1, 0, 0, 1) shared one entry and the
  // second animation parsed got the first one's curve (#462).
  test('curves with the same hashFor keep their own interpolator', () {
    var linear = _fade([0, 0], [1, 1]);
    var easeInOut = _fade([1, 0], [0, 1]);

    expect(_easedAtQuarter(linear), closeTo(0.25, 0.001));
    expect(_easedAtQuarter(easeInOut), lessThan(0.1));
  });

  test('the same curve parsed in another composition is shared', () {
    var a = _fade([0.167, 0.167], [0.833, 0.833]);
    var b = _fade([0.167, 0.167], [0.833, 0.833]);
    expect(
      identical(
        a.layers.first.transform.opacity!.keyframes.first.interpolator,
        b.layers.first.transform.opacity!.keyframes.first.interpolator,
      ),
      isTrue,
    );
  });
}
