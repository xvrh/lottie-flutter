import 'package:meta/meta.dart';

class Marker {
  static const String _carriageReturn = '\r';

  final String name;
  final double startFrame;
  final double durationFrames;

  Marker(this.name, {@required this.startFrame, @required this.durationFrames});

  bool matchesName(String name) {
    if (this.name.toLowerCase() == name.toLowerCase()) {
      return true;
    }

    // It is easy for a designer to accidentally include an extra newline which will cause the name to not match what they would
    // expect. This is a convenience to precent unneccesary confusion.
    if (this.name.endsWith(_carriageReturn) &&
        this.name.substring(0, this.name.length - 1).toLowerCase() ==
            name.toLowerCase()) {
      return true;
    }
    return false;
  }
}
