import 'package:flutter/foundation.dart';

@immutable
class FrameRate {
  static const max = FrameRate._special(0);
  static const composition = FrameRate._special(-1);

  final double framesPerSecond;

  const FrameRate(this.framesPerSecond) : assert(framesPerSecond > 0);
  const FrameRate._special(this.framesPerSecond);

  @override
  int get hashCode => framesPerSecond.hashCode;

  @override
  bool operator ==(other) =>
      other is FrameRate && other.framesPerSecond == framesPerSecond;

  @override
  String toString() {
    return 'FrameRate(${switch (framesPerSecond) {
      0 => 'max',
      -1 => 'composition',
      _ => framesPerSecond
    }})';
  }
}
