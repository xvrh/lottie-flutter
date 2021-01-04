import 'utils/mean_calculator.dart';
import 'utils/pair.dart';

class PerformanceTracker {
  final _frameListeners = <FrameListener>{};
  final _layerRenderTimes = <String, MeanCalculator>{};

  bool enabled = false;

  void recordRenderTime(String layerName, double millis) {
    if (!enabled) return;

    if (!_layerRenderTimes.containsKey(layerName)) {
      _layerRenderTimes[layerName] = MeanCalculator();
    }

    final calculator = _layerRenderTimes[layerName]!;

    calculator.add(millis);

    if (layerName == '__container') {
      for (var listener in _frameListeners) {
        listener.onFrameRendered(millis);
      }
    }
  }

  void addFrameListener(FrameListener listener) {
    _frameListeners.add(listener);
  }

  void removeFrameListener(FrameListener listener) {
    _frameListeners.remove(listener);
  }

  void clearRenderTimes() {
    _layerRenderTimes.clear();
  }

  void logRenderTimes() {
    if (!enabled) return;

    final sortedRenderTimes = getSortedRenderTimes();

    print('[Lottie] Render Times:');
    for (var layer in sortedRenderTimes) {
      print('[Lottie]\t\t${layer.first}: ${layer.second}ms');
    }
  }

  List<Pair<String, double>> getSortedRenderTimes() {
    if (!enabled) return [];

    final sortedRenderTimes = _layerRenderTimes.entries
        .map((e) => Pair(e.key, e.value.mean))
        .toList();

    sortedRenderTimes.sort((p1, p2) => p1.second.compareTo(p2.second));

    return sortedRenderTimes;
  }
}

abstract class FrameListener {
  void onFrameRendered(double renderTimeMs);
}
