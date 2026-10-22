import 'dart:convert';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/composition.dart' show frameChangesOf;
import 'package:lottie/src/frame_changes.dart';
import 'package:lottie/src/lottie.dart' show debugThrottleAnimationsInTests;

/// One simulated vsync at 60Hz.
const vsync = Duration(microseconds: 1000000 ~/ 60);

const _unlimited = Duration(days: 1);

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

/// The frames that are rendered differently from the frame before them.
List<int> _changes(
  FrameChangesScanner scanner, {
  Duration budget = _unlimited,
}) {
  var lastFrame = scanner.changes.lastFrame;
  var frames = <int>[];
  var frame = 0;
  while (true) {
    frame = scanner.nextChangeAfter(frame, budget: budget);
    if (frame > lastFrame) return frames;
    frames.add(frame);
  }
}

/// Records every frame of [composition], so that the time spent scanning does
/// not decide when a test animation ticks.
FrameChangesScanner _scanAll(LottieComposition composition) {
  var scanner = FrameChangesScanner(frameChangesOf(composition));
  _changes(scanner);
  return scanner;
}

void main() {
  group('FrameChangesScanner', () {
    test('finds the frames at which the rendering changes', () async {
      var composition = await _load();
      var changes = _changes(FrameChangesScanner(frameChangesOf(composition)));

      // Frame `i` is sampled at the keyframe time `i`. Entering the keyframe
      // [30, 60) on frame 30 counts as a change although the value is still
      // the same, and frame 60 is the first one of the hold keyframe. At its
      // end, rounding keeps the hold keyframe current on frame 90, so the move
      // back is reported from frame 91.
      expect(changes, [
        for (var i = 30; i <= 60; i++) i,
        for (var i = 91; i <= frameChangesOf(composition).lastFrame; i++) i,
      ]);
    });

    test('reports the first frame it had no time to scan', () async {
      var composition = await _load();
      var scanner = FrameChangesScanner(frameChangesOf(composition));

      // Out of budget after frame 1: frame 2 may or may not be a change.
      expect(scanner.nextChangeAfter(0, budget: Duration.zero), 2);
      expect(scanner.nextChangeAfter(0, budget: Duration.zero), 3);
      expect(scanner.nextChangeAfter(0, budget: _unlimited), 30);
    });

    test('scanning frame by frame gives the same record', () async {
      var expected = _changes(_scanAll(await _load()));

      var composition = await _load();
      var scanner = FrameChangesScanner(frameChangesOf(composition));
      var lastFrame = scanner.changes.lastFrame;
      // Backward, so that each call has to move the scratch drawable.
      for (var frame = lastFrame - 1; frame >= 0; frame--) {
        scanner.nextChangeAfter(frame, budget: Duration.zero);
      }

      expect(_changes(scanner, budget: Duration.zero), expected);
    });

    test('the record is shared by the scanners of a composition', () async {
      var composition = await _load();
      _scanAll(composition);

      var scanner = FrameChangesScanner(frameChangesOf(composition));
      expect(scanner.nextChangeAfter(0, budget: Duration.zero), 30);
    });
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
    /// [actual] shows the same thing as [reference].
    Future<void> pumpAndCompare(
      WidgetTester tester,
      FrameChangesScanner scanner, {
      required int count,
      required Key actual,
      required Key reference,
    }) async {
      var changes = scanner.changes;
      for (var i = 0; i < count; i++) {
        await tester.pump(vsync);
        var actualFrame = changes.frameAt(progressOf(tester, actual));
        var referenceFrame = changes.frameAt(progressOf(tester, reference));
        var nextChange = scanner.nextChangeAfter(
          min(actualFrame, referenceFrame),
          budget: _unlimited,
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
      _scanAll(composition);

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

    testWidgets('shows what an animation ticking at every frame shows', (
      tester,
    ) async {
      var composition = await _load();

      await tester.pumpWidget(
        withReference(Lottie(key: actual, composition: composition)),
      );
      // More than two loops, scanning the composition along the way.
      await pumpAndCompare(
        tester,
        FrameChangesScanner(frameChangesOf(await _load())),
        count: 300,
        actual: actual,
        reference: reference,
      );
    });

    testWidgets('a rebuild of the parent does not rewind the animation', (
      tester,
    ) async {
      var composition = await _load();
      var scanner = _scanAll(composition);

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
          scanner,
          count: 1,
          actual: actual,
          reference: reference,
        );
      }
    });

    testWidgets('a widget update ends the wait', (tester) async {
      var composition = await _load();
      _scanAll(composition);

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
      var scanner = _scanAll(composition);

      await tester.pumpWidget(
        withReference(
          Lottie(key: actual, composition: composition, repeat: false),
        ),
      );
      await pumpAndCompare(
        tester,
        scanner,
        count: 119,
        actual: actual,
        reference: reference,
      );
      expect(progressOf(tester, actual), lessThan(1));

      await pumpAndCompare(
        tester,
        scanner,
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
      var scanner = _scanAll(composition);

      Widget build({required bool enabled}) => TickerMode(
        enabled: enabled,
        child: withReference(Lottie(key: actual, composition: composition)),
      );

      await tester.pumpWidget(build(enabled: true));
      await pumpAndCompare(
        tester,
        scanner,
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
        scanner,
        count: 150,
        actual: actual,
        reference: reference,
      );
    });

    testWidgets('waits in real time under timeDilation', (tester) async {
      var composition = await _load();
      _scanAll(composition);

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
        _scanAll(composition);

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
