import 'dart:convert';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/frame_changes.dart';
import 'package:lottie/src/lottie.dart' show debugThrottleAnimationsInTests;

/// One simulated vsync at 60Hz.
const vsync = Duration(microseconds: 1000000 ~/ 60);

const _ease = '"o": {"x": 0.4, "y": 0}, "i": {"x": 0.6, "y": 1}';

/// Waits until frame 30, moves right until 60, waits (hold keyframe) until 90,
/// moves back until 120.
const _pausesAndMoves =
    '''
  {"t": 0, "s": [10, 5], $_ease},
  {"t": 30, "s": [10, 5], $_ease},
  {"t": 60, "s": [40, 5], "h": 1},
  {"t": 90, "s": [40, 5], $_ease},
  {"t": 120, "s": [10, 5]}
''';

/// Waits until frame 30, moves right until 60, then waits until the end.
const _endsWithPause =
    '''
  {"t": 0, "s": [10, 5], $_ease},
  {"t": 30, "s": [10, 5], $_ease},
  {"t": 60, "s": [40, 5], $_ease},
  {"t": 120, "s": [40, 5]}
''';

/// A 10x10 red square in a 60x30 composition of 120 frames at 60 fps.
Future<LottieComposition> _load({String position = _pausesAndMoves}) {
  return LottieComposition.fromBytes(
    utf8.encode('''
{
  "v": "5.7.4",
  "fr": 60,
  "ip": 0,
  "op": 120,
  "w": 60,
  "h": 30,
  "layers": [
    {
      "ty": 1,
      "ind": 1,
      "nm": "Square",
      "sw": 10,
      "sh": 10,
      "sc": "#ff0000",
      "ip": 0,
      "op": 121,
      "st": 0,
      "sr": 1,
      "ks": {
        "o": {"a": 0, "k": 100},
        "r": {"a": 0, "k": 0},
        "p": {"a": 1, "k": [$position]},
        "a": {"a": 0, "k": [0, 0, 0]},
        "s": {"a": 0, "k": [100, 100, 100]}
      }
    }
  ]
}
'''),
  );
}

/// A progress at which [frame] is on screen.
double _progressOf(LottieComposition composition, int frame) {
  return min(1, (frame + 0.5) / FrameChanges.of(composition).frameCount);
}

/// Plays every frame of [composition] through [drawable] (by default one that
/// draws the plain composition), which fills its record.
void _play(LottieComposition composition, {LottieDrawable? drawable}) {
  drawable ??= LottieDrawable(composition);
  for (
    var frame = 0;
    frame <= FrameChanges.of(composition).lastFrame;
    frame++
  ) {
    drawable.setProgress(_progressOf(composition, frame));
  }
}

/// The frames of [composition] recorded as rendered differently from the frame
/// before them, or not observed yet.
List<int> _changes(LottieComposition composition) {
  var changes = FrameChanges.of(composition);
  var frames = <int>[];
  var frame = 0;
  while (true) {
    frame = changes.nextChangeAfter(frame);
    if (frame > changes.lastFrame) return frames;
    frames.add(frame);
  }
}

void main() {
  group('FrameChanges', () {
    test('is filled by playing the composition', () async {
      var composition = await _load();
      _play(composition);

      // Frame `i` is sampled at the keyframe time `i`. Entering the keyframe
      // [30, 60) on frame 30 counts as a change although the value is still
      // the same, and frame 60 is the first one of the hold keyframe. At its
      // end, rounding keeps the hold keyframe current on frame 90, so the move
      // back is reported from frame 91.
      expect(_changes(composition), [
        for (var i = 30; i <= 60; i++) i,
        for (var i = 91; i <= FrameChanges.of(composition).lastFrame; i++) i,
      ]);
    });

    test('a frame not played yet counts as a change', () async {
      var composition = await _load();
      var changes = FrameChanges.of(composition);
      expect(changes.nextChangeAfter(0), 1);

      var drawable = LottieDrawable(composition);
      for (var frame = 0; frame <= 10; frame++) {
        drawable.setProgress(_progressOf(composition, frame));
      }
      expect(changes.nextChangeAfter(0), 11);
    });

    test('a jump over frames that reports no change records them', () async {
      var composition = await _load();
      LottieDrawable(composition)
        ..setProgress(_progressOf(composition, 0))
        ..setProgress(_progressOf(composition, 20));
      expect(FrameChanges.of(composition).nextChangeAfter(0), 21);
    });

    test('a jump that reports a change records nothing', () async {
      var composition = await _load();
      LottieDrawable(composition)
        ..setProgress(_progressOf(composition, 0))
        ..setProgress(_progressOf(composition, 40));
      expect(FrameChanges.of(composition).nextChangeAfter(0), 1);
    });

    test('a move backward records nothing', () async {
      var composition = await _load();
      LottieDrawable(composition)
        ..setProgress(_progressOf(composition, 40))
        ..setProgress(_progressOf(composition, 10));
      var changes = FrameChanges.of(composition);
      expect(changes.nextChangeAfter(0), 1);
      expect(changes.nextChangeAfter(10), 11);
    });

    test('a change is never forgotten', () async {
      var composition = await _load();
      var changes = FrameChanges.of(composition);
      var from = _progressOf(composition, 4);
      var to = _progressOf(composition, 5);
      changes.observe(from, to, changed: true);
      changes.observe(from, to, changed: false);
      expect(changes.nextChangeAfter(0), 1);
      expect(changes.nextChangeAfter(4), 5);
    });

    for (var (description, build) in [
      (
        'with delegates',
        (LottieComposition composition) =>
            LottieDrawable(composition, delegates: const LottieDelegates()),
      ),
      (
        'at FrameRate.max',
        (LottieComposition composition) =>
            LottieDrawable(composition, frameRate: FrameRate.max),
      ),
      (
        'at a custom frame rate',
        (LottieComposition composition) =>
            LottieDrawable(composition, frameRate: const FrameRate(60)),
      ),
    ]) {
      test('is not filled by a drawable $description', () async {
        var composition = await _load();
        _play(composition, drawable: build(composition));
        expect(FrameChanges.of(composition).nextChangeAfter(0), 1);
      });
    }
  });

  group('Lottie', () {
    var frames = 0;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized().addPersistentFrameCallback(
        (_) => frames++,
      );
    });
    setUp(() => debugThrottleAnimationsInTests = true);
    tearDown(() => debugThrottleAnimationsInTests = false);

    double progressOf(WidgetTester tester, Key key) {
      return tester
          .widget<RawLottie>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(RawLottie),
            ),
          )
          .progress;
    }

    /// Pumps [count] vsyncs and checks after each one that the animation
    /// [actual] shows the same thing as [reference], according to a complete
    /// record [oracle] of their composition.
    Future<void> pumpAndCompare(
      WidgetTester tester,
      FrameChanges oracle, {
      required int count,
      required Key actual,
      required Key reference,
    }) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(vsync);
        var actualFrame = oracle.frameAt(progressOf(tester, actual));
        var referenceFrame = oracle.frameAt(progressOf(tester, reference));
        var nextChange = oracle.nextChangeAfter(
          min(actualFrame, referenceFrame),
        );
        expect(
          nextChange,
          greaterThan(max(actualFrame, referenceFrame)),
          reason:
              'vsync $i shows frame $actualFrame instead of $referenceFrame',
        );
      }
    }

    const actual = Key('actual');
    const reference = Key('reference');

    /// [actual] next to an animation that ticks at every composition frame: a
    /// delegate may change the rendering at any time.
    Widget withReference(Lottie lottie) {
      return Row(
        textDirection: TextDirection.ltr,
        children: [
          lottie,
          Lottie(
            key: reference,
            composition: lottie.composition,
            repeat: lottie.repeat,
            delegates: const LottieDelegates(),
          ),
        ],
      );
    }

    testWidgets('schedules no frame while nothing changes', (tester) async {
      var composition = await _load();
      _play(composition);

      await tester.pumpWidget(Lottie(composition: composition));
      // The first tick starts the animation, the second one measures its speed.
      await tester.pump();
      await tester.pump(vsync);

      // Vsync `i` is slightly ahead of the composition frame `i`, so it draws
      // the frame `i - 1`. Nothing changes until the frame 30, and the ticks
      // resume 200 ms (12 frames) before it.
      frames = 0;
      for (var i = 2; i <= 17; i++) {
        await tester.pump(vsync);
      }
      expect(frames, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Every vsync from there to the end of the move, at the frame 60.
      frames = 0;
      for (var i = 18; i <= 61; i++) {
        await tester.pump(vsync);
      }
      expect(frames, 44);

      // The hold keyframe, until the frame 91: the ticks resume at the frame
      // 79, 12 frames before the change again.
      frames = 0;
      for (var i = 62; i <= 79; i++) {
        await tester.pump(vsync);
      }
      expect(frames, 0);

      frames = 0;
      for (var i = 80; i <= 92; i++) {
        await tester.pump(vsync);
      }
      expect(frames, 13);
    });

    testWidgets('ticks at every frame during the first loop, then waits', (
      tester,
    ) async {
      var composition = await _load();

      await tester.pumpWidget(Lottie(composition: composition));
      await tester.pump();

      // Nothing is known about the composition yet.
      frames = 0;
      for (var i = 1; i <= 121; i++) {
        await tester.pump(vsync);
      }
      expect(frames, 121);

      // The second loop waits for the first move: the ticks resume 12 frames
      // ahead of it, on the frame 18.
      frames = 0;
      for (var i = 122; i <= 138; i++) {
        await tester.pump(vsync);
      }
      expect(frames, 0);

      frames = 0;
      await tester.pump(vsync);
      expect(frames, 1);
      expect(
        FrameChanges.of(
          composition,
        ).frameAt(tester.widget<RawLottie>(find.byType(RawLottie)).progress),
        18,
      );
    });

    testWidgets('shows what an animation ticking at every frame shows', (
      tester,
    ) async {
      var composition = await _load();
      // The record of the composition is filled along the way; the oracle is
      // a complete record of another copy of it.
      var oracle = await _load();
      _play(oracle);

      await tester.pumpWidget(
        withReference(Lottie(key: actual, composition: composition)),
      );
      // More than two loops.
      await pumpAndCompare(
        tester,
        FrameChanges.of(oracle),
        count: 300,
        actual: actual,
        reference: reference,
      );
    });

    testWidgets('a rebuild of the parent does not rewind the animation', (
      tester,
    ) async {
      var composition = await _load();
      _play(composition);

      await tester.pumpWidget(
        withReference(Lottie(key: actual, composition: composition)),
      );
      for (var i = 0; i < 300; i++) {
        if (i % 7 == 0) {
          await tester.pumpWidget(
            withReference(Lottie(key: actual, composition: composition)),
          );
        }
        await pumpAndCompare(
          tester,
          FrameChanges.of(composition),
          count: 1,
          actual: actual,
          reference: reference,
        );
      }
    });

    testWidgets('a widget update ends the wait', (tester) async {
      var composition = await _load();
      _play(composition);

      await tester.pumpWidget(Lottie(composition: composition));
      await tester.pump();
      for (var i = 1; i <= 10; i++) {
        await tester.pump(vsync);
      }

      // With a delegate, the frames to skip are not known anymore.
      await tester.pumpWidget(
        Lottie(composition: composition, delegates: const LottieDelegates()),
      );
      frames = 0;
      for (var i = 11; i <= 20; i++) {
        await tester.pump(vsync);
      }
      expect(frames, 10);
    });

    testWidgets('an animation that ends with a pause completes on time', (
      tester,
    ) async {
      var composition = await _load(position: _endsWithPause);
      _play(composition);

      await tester.pumpWidget(
        withReference(
          Lottie(key: actual, composition: composition, repeat: false),
        ),
      );
      await pumpAndCompare(
        tester,
        FrameChanges.of(composition),
        count: 119,
        actual: actual,
        reference: reference,
      );
      expect(progressOf(tester, actual), lessThan(1));

      await pumpAndCompare(
        tester,
        FrameChanges.of(composition),
        count: 3,
        actual: actual,
        reference: reference,
      );
      expect(progressOf(tester, actual), 1);
      expect(progressOf(tester, reference), 1);
    });

    testWidgets('TickerMode pauses and resumes a waiting animation', (
      tester,
    ) async {
      var composition = await _load();
      _play(composition);

      Widget build({required bool enabled}) => TickerMode(
        enabled: enabled,
        child: withReference(Lottie(key: actual, composition: composition)),
      );

      await tester.pumpWidget(build(enabled: true));
      await pumpAndCompare(
        tester,
        FrameChanges.of(composition),
        count: 10,
        actual: actual,
        reference: reference,
      );

      await tester.pumpWidget(build(enabled: false));
      await tester.pump();
      frames = 0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(vsync);
      }
      expect(frames, 0);

      await tester.pumpWidget(build(enabled: true));
      await pumpAndCompare(
        tester,
        FrameChanges.of(composition),
        count: 150,
        actual: actual,
        reference: reference,
      );
    });

    testWidgets(
      'ticks at every frame while Lottie.skipUnchangedFrames is off',
      (tester) async {
        var composition = await _load();
        _play(composition);
        Lottie.skipUnchangedFrames = false;
        addTearDown(() => Lottie.skipUnchangedFrames = true);

        await tester.pumpWidget(Lottie(composition: composition));
        await tester.pump();
        await tester.pump(vsync);

        frames = 0;
        for (var i = 2; i <= 29; i++) {
          await tester.pump(vsync);
        }
        expect(frames, 28);

        // The switch is read at every tick: the next pause is waited for.
        Lottie.skipUnchangedFrames = true;
        for (var i = 30; i <= 61; i++) {
          await tester.pump(vsync);
        }
        frames = 0;
        for (var i = 62; i <= 79; i++) {
          await tester.pump(vsync);
        }
        expect(frames, 0);
      },
    );

    testWidgets('waits in real time under timeDilation', (tester) async {
      var composition = await _load();
      _play(composition);

      timeDilation = 2;
      try {
        await tester.pumpWidget(Lottie(composition: composition));
        await tester.pump();
        await tester.pump(vsync);
        await tester.pump(vsync);

        // The animation runs at half speed: the ticks resume at the frame 18,
        // which is 36 vsyncs away.
        frames = 0;
        for (var i = 3; i <= 35; i++) {
          await tester.pump(vsync);
        }
        expect(frames, 0);

        for (var i = 36; i <= 70; i++) {
          await tester.pump(vsync);
        }
        var progress = tester
            .widget<RawLottie>(find.byType(RawLottie))
            .progress;
        expect(progress * 120, closeTo(70 / 2, 1.5));
      } finally {
        timeDilation = 1;
      }
    });

    for (var (description, build) in [
      (
        'with delegates',
        (LottieComposition composition) => Lottie(
          composition: composition,
          delegates: const LottieDelegates(),
        ),
      ),
      (
        'in reverse',
        (LottieComposition composition) =>
            Lottie(composition: composition, reverse: true),
      ),
      (
        'at a custom frame rate',
        (LottieComposition composition) =>
            Lottie(composition: composition, frameRate: const FrameRate(60)),
      ),
    ]) {
      testWidgets('ticks at every frame $description', (tester) async {
        var composition = await _load();
        _play(composition);

        await tester.pumpWidget(build(composition));
        await tester.pump();
        await tester.pump(vsync);

        frames = 0;
        for (var i = 2; i <= 29; i++) {
          await tester.pump(vsync);
        }
        expect(frames, 28);
      });
    }
  });
}
