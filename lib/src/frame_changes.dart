import 'package:flutter/foundation.dart';

import 'composition.dart';
import 'frame_rate.dart';

/// Records the frames of a [LottieComposition] at which its rendering changes.
///
/// The frames are the ones drawn with [FrameRate.composition]: frame `i` is on
/// screen while the progress is in `[i / frameCount, (i + 1) / frameCount)`.
/// There is one record per composition, filled as a by-product of playing it:
/// `LottieDrawable.setProgress` reports whether the frame it moves to is
/// rendered differently from the one it leaves (the flag `RenderLottie`
/// repaints on, which accounts for everything that goes through `setProgress`:
/// pre-compositions, time remapping, masks, mattes, the in and out points of
/// the layers...), and [observe] keeps that answer. A frame that has not been
/// observed yet counts as a change.
class FrameChanges {
  static final _byComposition = Expando<FrameChanges>();

  /// The record of [composition].
  static FrameChanges of(LottieComposition composition) =>
      _byComposition[composition] ??= FrameChanges._(composition);

  /// Compositions longer than this (28 minutes at 60 fps) are recorded up to
  /// this frame only; the frames after it count as changing.
  static const _maxRecordedFrames = 100000;

  static const _unknown = 0;
  static const _unchanged = 1;
  static const _changed = 2;

  FrameChanges._(this.composition)
    : frameCount = composition.durationFrames + 0.01 {
    lastFrame = frameCount.isFinite && frameCount > 0 ? frameCount.floor() : 0;
    _states = Uint8List(
      (lastFrame < _maxRecordedFrames ? lastFrame : _maxRecordedFrames) + 1,
    );
  }

  final LottieComposition composition;

  /// The duration of the composition in frames, as used by
  /// [LottieComposition.roundProgress].
  final double frameCount;

  /// The last frame of the composition; the first one is 0.
  late final int lastFrame;

  /// For each frame, whether it is rendered differently from the frame before.
  late final Uint8List _states;

  /// The frame on screen at [progress].
  int frameAt(double progress) {
    return (_roundProgress(progress) * frameCount).round();
  }

  double _roundProgress(double progress) =>
      composition.roundProgress(progress, frameRate: FrameRate.composition);

  int _stateOf(int frame) => frame < _states.length ? _states[frame] : _changed;

  /// Keeps what a drawable reported when moving from [previousProgress] to
  /// [progress]: [changed] is whether the rendering differs.
  ///
  /// A move to the next frame tells about that frame. A move that jumps over
  /// frames and reports no change tells that every frame jumped over is
  /// rendered like the frame before it; one that reports a change tells
  /// nothing about them. A move backward tells nothing either.
  void observe(
    double previousProgress,
    double progress, {
    required bool changed,
  }) {
    var from = frameAt(previousProgress);
    var to = frameAt(progress);
    if (to <= from) return;
    if (to == from + 1) {
      _record(to, changed: changed);
    } else if (!changed) {
      for (var frame = from + 1; frame <= to; frame++) {
        _record(frame, changed: false);
      }
    }
  }

  void _record(int frame, {required bool changed}) {
    if (frame >= _states.length) return;
    // A change is never forgotten: a drawable with more than the composition
    // to draw can report more changes than another, never fewer.
    if (changed || _states[frame] == _unknown) {
      _states[frame] = changed ? _changed : _unchanged;
    }
  }

  /// The first frame after [frame] that may be rendered differently from the
  /// frame before it: a frame observed as a change, or not observed yet.
  /// Returns `lastFrame + 1` if the composition is rendered like [frame] until
  /// its end.
  int nextChangeAfter(int frame) {
    for (var next = frame + 1; next <= lastFrame; next++) {
      if (_stateOf(next) != _unchanged) return next;
    }
    return lastFrame + 1;
  }
}
