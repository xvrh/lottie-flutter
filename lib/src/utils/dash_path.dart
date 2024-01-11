import 'dart:math';
import 'dart:ui';

Path dashPath(
  Path source, {
  required List<double> intervals,
  double? phase,
}) {
  assert(intervals.length >= 2);
  phase ??= 0;

  var dest = Path();
  for (final metric in source.computeMetrics()) {
    for (var dash in _dashes(metric.length, intervals, phase)) {
      dest.addPath(metric.extractPath(dash.left, dash.right), Offset.zero);
    }
  }

  return dest;
}

Iterable<Rect> _dashes(
    double length, List<double> intervals, double phase) sync* {
  var intervalLength = intervals.fold<double>(0, (a, b) => a + b);

  var distance = 0.0;
  while (distance < length) {
    var position = (distance + phase) % intervalLength;
    var end = 0.0;
    for (var i = 0; i < intervals.length; i++) {
      end += intervals[i];
      if (end > position || i == intervals.length - 1) {
        var offset = max(0.1, end - position);

        if (i.isEven) {
          yield Rect.fromLTRB(distance, 0, min(length, distance + offset), 0);
        }

        distance += offset;
        break;
      }
    }
  }
}
