import 'package:meta/meta.dart';
import '../../lottie.dart';

class Marker {
  final LottieComposition _composition;
  final String name;
  final double startFrame;
  final double durationFrames;

  Marker(this._composition, this.name,
      {@required this.startFrame, @required this.durationFrames});

  bool matchesName(String name) {
    return this.name.trim().toLowerCase() == name.toLowerCase();
  }

  double get start =>
      (startFrame - _composition.startFrame) / _composition.durationFrames;

  double get end =>
      (startFrame + durationFrames - _composition.startFrame) /
      _composition.durationFrames;
}
