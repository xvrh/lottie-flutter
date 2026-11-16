import 'dart:ui';

import '../composition.dart';
import '../utils/misc.dart';
import '../value/keyframe.dart';

/// How a `loopOut` or `loopIn` expression repeats the keyframes.
enum LoopType {
  /// `'cycle'`, the default: plays the keyframes again.
  cycle,

  /// `'pingpong'`: plays the keyframes backward, then forward again.
  pingPong,

  /// `'offset'`: plays the keyframes again from the value the previous
  /// repetition ended on.
  offset,

  /// `'continue'`: keeps the velocity of the last keyframe (of the first one
  /// for `loopIn`).
  continueMotion,
}

/// The keyframes of a property repeated by an After Effects `loopOut()` or
/// `loopIn()` expression, played without evaluating the expression.
///
/// `loopOut` repeats keyframes after the last one, `loopIn` before the first
/// one. The parser reads the expression with [parse] and gives the loop to the
/// animation of the property, which follows it with a [LoopPosition]. The
/// time mapping is lottie-web's, without two of its slips: `continue` keeps
/// the velocity of points too, and `loopIn` cycles the right keyframes when the
/// first one isn't on frame 0.
class KeyframeLoop {
  KeyframeLoop._(
    this.type,
    this._composition, {
    required this.isOut,
    required this.startFrame,
    required this.endFrame,
    required (double, double) continuedKeyframe,
  }) : _continuedKeyframe = continuedKeyframe,
       _continueFrames =
           (continuedKeyframe.$2 - continuedKeyframe.$1) * continueStep;

  /// `loopOut(type, numKeyframes)`, `loopIn(...)` or their `loop_out` and
  /// `loop_in` aliases, alone or assigned to `$bm_rt` as Bodymovin exports it.
  /// No two runs of spaces can match the same spaces, which keeps a long run
  /// from making the match quadratic.
  static final _expression = RegExp(
    r'^\s*(?:var\s+\$bm_rt\s*;\s*)?(?:\$bm_rt\s*=\s*)?'
    r'(loopOut|loop_out|loopIn|loop_in)\s*\(\s*'
    r'''(?:(['"])(\w*)\2\s*(?:,\s*(\d+)\s*)?)?\)\s*(?:;\s*)?$''',
  );

  /// The part of a keyframe the velocity of `continue` is measured over.
  static const continueStep = 0.001;

  final LoopType type;

  /// Whether this is a `loopOut`, which plays after [endFrame]. A `loopIn`
  /// plays before [startFrame].
  final bool isOut;

  /// The frame of the first keyframe that repeats.
  final double startFrame;

  /// The frame of the last keyframe that repeats.
  final double endFrame;

  /// The start and end frames of the keyframe whose velocity `continue` keeps:
  /// the last one, or the first one for `loopIn`.
  final (double, double) _continuedKeyframe;

  /// The frames [continueStep] of the continued keyframe lasts.
  final double _continueFrames;

  final LottieComposition _composition;

  /// Reads [expression], the expression of the property with [keyframes].
  ///
  /// `isLoop` is false if [expression] is not a loop that can be played: the
  /// property then holds its first and last values, like a property with any
  /// other expression. `loop` is null if the keyframes have nothing to repeat.
  static ({bool isLoop, KeyframeLoop? loop}) parse(
    String expression,
    List<Keyframe<Object?>> keyframes,
  ) {
    var match = _expression.firstMatch(expression);
    if (match == null) return (isLoop: false, loop: null);
    var type = switch (match[3]?.toLowerCase()) {
      null || '' || 'cycle' => LoopType.cycle,
      'pingpong' => LoopType.pingPong,
      'offset' => LoopType.offset,
      'continue' => LoopType.continueMotion,
      _ => null,
    };
    if (type == null) return (isLoop: false, loop: null);

    var composition = keyframes.firstOrNull?.composition;
    // A value that isn't animated has nothing to repeat.
    if (composition == null) return (isLoop: true, loop: null);
    if (type == LoopType.offset || type == LoopType.continueMotion) {
      var value = keyframes.first.startValue;
      if (value is! num && value is! Offset) return (isLoop: false, loop: null);
    }

    // The frames of the keyframes in the file: the last one is gone from
    // [keyframes] if it only gave the end of the keyframe before it.
    var frames = [
      for (var keyframe in keyframes) keyframe.startFrame,
      ?keyframes.last.endFrame,
    ];
    var last = frames.length - 1;
    if (last == 0) return (isLoop: true, loop: null);
    var count = int.tryParse(match[4] ?? '0') ?? last;
    // 0, the default, repeats all the keyframes.
    if (count == 0 || count > last) count = last;
    var isOut = match[1]!.toLowerCase().endsWith('out');
    var (startFrame, endFrame) = isOut
        ? (frames[last - count], frames[last])
        : (frames[0], frames[count]);
    var continuedKeyframe = isOut
        ? (frames[last - 1], frames[last])
        : (frames[0], frames[1]);
    if (!(endFrame > startFrame) ||
        type == LoopType.continueMotion &&
            !(continuedKeyframe.$2 > continuedKeyframe.$1)) {
      return (isLoop: true, loop: null);
    }
    return (
      isLoop: true,
      loop: KeyframeLoop._(
        type,
        composition,
        isOut: isOut,
        startFrame: startFrame,
        endFrame: endFrame,
        continuedKeyframe: continuedKeyframe,
      ),
    );
  }

  /// The progress of the first keyframe that repeats.
  double get startProgress => _composition.progressOfFrame(startFrame);

  /// The progress of the last keyframe that repeats.
  double get endProgress => _composition.progressOfFrame(endFrame);

  /// A progress inside the keyframe whose velocity `continue` keeps.
  double get continuedKeyframe {
    var (start, end) = _continuedKeyframe;
    return _composition.progressOfFrame((start + end) / 2);
  }
}

/// Where a [KeyframeLoop] is in an animation: which repetition of its
/// keyframes plays, and where they are read.
class LoopPosition {
  LoopPosition(this.loop);

  final KeyframeLoop loop;

  /// The progress the keyframes are read at.
  double keyframeProgress = 0;

  /// The repetition that plays: 0 where the loop doesn't play, then 1, 2... for
  /// a `loopOut` and -1, -2... for a `loopIn`. Always 0 for `continue`, which
  /// repeats nothing.
  int repetition = 0;

  /// How many times the value changes by the difference between two values of
  /// the keyframes: from the first repeated keyframe to the last one for
  /// `offset`, over a [KeyframeLoop.continueStep] at the end of the continued
  /// keyframe for `continue`. 0 for the other loops.
  double times = 0;

  /// Moves to [progress].
  ///
  /// Returns false where the loop doesn't play, from the first repeated
  /// keyframe on for a `loopIn`, until the last one for a `loopOut`.
  /// [keyframeProgress] is then left to the caller.
  bool moveTo(double progress) {
    repetition = 0;
    times = 0;
    var composition = loop._composition;
    var durationFrames = composition.durationFrames;
    if (!(durationFrames > 0)) return false;
    // In the frames of the keyframes, snapped like `CompositionLayer` does, so
    // that a frame repeating a keyframe gets exactly its progress.
    var frame = MiscUtils.wholeFrame(
      composition.startFrame + progress * durationFrames,
    );
    if (!frame.isFinite) return false;
    var start = loop.startFrame;
    var end = loop.endFrame;
    var cycle = end - start;
    double keyframeFrame;
    if (loop.isOut) {
      if (frame <= end) return false;
      var elapsed = frame - start;
      var phase = elapsed % cycle;
      // From the phase, so that the two agree when the division rounds.
      var cycles = ((elapsed - phase) / cycle).round();
      if (loop.type == LoopType.continueMotion) {
        keyframeFrame = end;
        times = (frame - end) / loop._continueFrames;
      } else {
        keyframeFrame = loop.type == LoopType.pingPong && cycles.isOdd
            ? end - phase
            : start + phase;
        repetition = cycles;
      }
    } else {
      if (frame >= start) return false;
      var elapsed = start - frame;
      var phase = elapsed % cycle;
      var cycles = ((elapsed - phase) / cycle).round();
      if (loop.type == LoopType.continueMotion) {
        keyframeFrame = start;
        times = elapsed / loop._continueFrames;
      } else {
        keyframeFrame = loop.type == LoopType.pingPong && cycles.isEven
            ? start + phase
            : end - phase;
        repetition = -(cycles + 1);
      }
    }
    if (loop.type == LoopType.offset) {
      times = repetition.toDouble();
    }
    keyframeProgress = composition.progressOfFrame(keyframeFrame);
    return true;
  }
}
