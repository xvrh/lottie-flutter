import 'dart:developer';

class L {
  static final int _maxDepth = 20;
  static bool _traceEnabled = false;
  static late List<String?> _sections;
  static late List<int> _startTimeNs;
  static int _traceDepth = 0;
  static int _depthPastMaxDepth = 0;

  static bool get traceEnabled => _traceEnabled;
  static set traceEnabled(bool enabled) {
    if (_traceEnabled == enabled) {
      return;
    }
    _traceEnabled = enabled;
    if (_traceEnabled) {
      _sections = List.filled(_maxDepth, null);
      _startTimeNs = List.filled(_maxDepth, 0);
    }
  }

  static void beginSection(String section) {
    if (!_traceEnabled) {
      return;
    }
    if (_traceDepth == _maxDepth) {
      _depthPastMaxDepth++;
      return;
    }
    _sections[_traceDepth] = section;
    _startTimeNs[_traceDepth] = DateTime.now().microsecondsSinceEpoch;
    Timeline.startSync('Lottie::$section');
    _traceDepth++;
  }

  static double endSection(String section) {
    if (_depthPastMaxDepth > 0) {
      _depthPastMaxDepth--;
      return 0;
    }
    if (!_traceEnabled) {
      return 0;
    }
    _traceDepth--;
    if (_traceDepth == -1) {
      throw StateError("Can't end trace section. There are none.");
    }
    if (section != _sections[_traceDepth]) {
      throw StateError('Unbalanced trace call $section'
          '. Expected ${_sections[_traceDepth]}.');
    }
    Timeline.finishSync();
    return (DateTime.now().microsecondsSinceEpoch - _startTimeNs[_traceDepth]) /
        1000;
  }
}
