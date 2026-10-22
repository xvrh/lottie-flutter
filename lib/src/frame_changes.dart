import 'package:flutter/foundation.dart';
import 'composition.dart';
import 'frame_rate.dart';
import 'lottie_drawable.dart';

/// Records the frames of a [LottieComposition] at which its rendering changes.
///
/// The frames are the ones drawn with [FrameRate.composition]: frame `i` is on
/// screen while the progress is in `[i / frameCount, (i + 1) / frameCount)`.
/// The record starts empty and is filled by a [FrameChangesScanner]. There is
/// one per composition, so that a frame is scanned once, however many
/// animations play the composition.
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
    _unknownCount = _states.length - 1;
  }

  final LottieComposition composition;

  /// The duration of the composition in frames, as used by
  /// [LottieComposition.roundProgress].
  final double frameCount;

  /// The last frame of the composition; the first one is 0.
  late final int lastFrame;

  /// For each frame, whether it is rendered differently from the frame before.
  late final Uint8List _states;
  late int _unknownCount;

  bool get _isComplete => _unknownCount == 0;

  /// The frame on screen at [progress].
  int frameAt(double progress) {
    return (_roundProgress(progress) * frameCount).round();
  }

  /// The progress given to the drawable to render [frame].
  double _progressOf(int frame) {
    var progress = (frame + 0.5) / frameCount;
    return _roundProgress(progress < 1 ? progress : 1);
  }

  double _roundProgress(double progress) =>
      composition.roundProgress(progress, frameRate: FrameRate.composition);

  int _stateOf(int frame) => frame < _states.length ? _states[frame] : _changed;

  void _record(int frame, {required bool changed}) {
    if (_states[frame] == _unknown) {
      _unknownCount--;
    }
    _states[frame] = changed ? _changed : _unchanged;
  }
}

/// Fills a [FrameChanges] on demand, by stepping a scratch [LottieDrawable]
/// from one frame to the next and recording whether it reports a change. This
/// is the signal `RenderLottie` relies on to decide whether to repaint, so it
/// accounts for everything that goes through `setProgress`: pre-compositions,
/// time remapping, masks, mattes, the in and out points of the layers...
///
/// The scratch drawable is a copy of the whole layer tree. It is created when
/// a frame has to be scanned and freed once the record is complete, or earlier
/// by [releaseDrawable], when the animation stops ticking.
class FrameChangesScanner {
  FrameChangesScanner(this.changes);

  /// The number of scratch drawables currently held by scanners, in debug mode.
  @visibleForTesting
  static int debugScratchDrawableCount = 0;

  final FrameChanges changes;

  LottieDrawable? _drawable;
  int _drawableFrame = -1;

  /// Returns the first frame after [frame] that may be rendered differently
  /// from the frame before it, or `lastFrame + 1` if the composition is
  /// rendered like [frame] until its end.
  ///
  /// The frames that are not recorded yet are scanned for at most [budget],
  /// and at least one of them is. The first frame left unscanned is returned
  /// as if it was a change, so that calling again from this frame resumes the
  /// scan.
  int nextChangeAfter(int frame, {required Duration budget}) {
    var result = changes.lastFrame + 1;
    Stopwatch? stopwatch;
    for (var next = frame + 1; next <= changes.lastFrame; next++) {
      if (changes._stateOf(next) == FrameChanges._unknown) {
        if (stopwatch == null) {
          stopwatch = Stopwatch()..start();
        } else if (stopwatch.elapsedMicroseconds >= budget.inMicroseconds) {
          result = next;
          break;
        }
        _scan(next);
      }
      if (changes._stateOf(next) == FrameChanges._changed) {
        result = next;
        break;
      }
    }
    if (changes._isComplete) {
      // Nothing is left to scan, by this scanner or by another one.
      releaseDrawable();
    }
    return result;
  }

  void _scan(int frame) {
    var drawable = _drawable;
    if (drawable == null) {
      // FrameRate.max: the progress given below is already rounded to the
      // frame.
      drawable = _drawable = LottieDrawable(
        changes.composition,
        frameRate: FrameRate.max,
      );
      assert(() {
        debugScratchDrawableCount++;
        return true;
      }());
    }
    if (_drawableFrame != frame - 1) {
      drawable.setProgress(changes._progressOf(frame - 1));
    }
    var changed = drawable.setProgress(changes._progressOf(frame));
    _drawableFrame = frame;
    changes._record(frame, changed: changed);
  }

  /// Frees the scratch drawable. The scanner stays usable: it creates a new
  /// one if a frame has to be scanned.
  void releaseDrawable() {
    if (_drawable == null) return;
    _drawable = null;
    _drawableFrame = -1;
    assert(() {
      debugScratchDrawableCount--;
      return true;
    }());
  }
}
