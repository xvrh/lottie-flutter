import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/lottie.dart' show debugThrottleAnimationsInTests;

/// One simulated vsync at 60Hz. Coarser steps (e.g. 16ms) make the simulated
/// clock run slower than the throttle targets and legitimately drop frames.
const vsync = Duration(microseconds: 1000000 ~/ 60);

Future<LottieComposition> loadComposition(String path) {
  return LottieComposition.fromBytes(File(path).readAsBytesSync());
}

/// The vsync ticker notifies every display frame, but the widget should only
/// rebuild when the frame-rate-rounded progress actually changes, so a 30fps
/// composition on a 60Hz display rebuilds ~30 times/second, not 60.
void main() {
  setUp(() => debugThrottleAnimationsInTests = true);
  tearDown(() => debugThrottleAnimationsInTests = false);

  testWidgets('rebuilds are throttled to the composition frame rate', (
    tester,
  ) async {
    var composition = await loadComposition('example/assets/LottieLogo1.json');
    expect(composition.frameRate, 30);

    var builds = 0;
    var previous = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (element.widget is Lottie) builds++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previous);

    await tester.pumpWidget(Lottie(composition: composition));
    await tester.pump();
    builds = 0;

    // Pump 60 vsync frames (~1 second at 60Hz).
    for (var i = 0; i < 60; i++) {
      await tester.pump(vsync);
    }

    // Without throttling this would be 60 (one rebuild per vsync).
    expect(builds, lessThan(40));
    expect(builds, greaterThan(20));
  });

  testWidgets('FrameRate.max rebuilds every frame', (tester) async {
    var composition = await loadComposition('example/assets/LottieLogo1.json');

    var builds = 0;
    var previous = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (element.widget is Lottie) builds++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previous);

    await tester.pumpWidget(
      Lottie(composition: composition, frameRate: FrameRate.max),
    );
    await tester.pump();
    builds = 0;

    for (var i = 0; i < 60; i++) {
      await tester.pump(vsync);
    }

    expect(builds, greaterThan(50));
  });

  testWidgets('no engine frame is scheduled between composition frames', (
    tester,
  ) async {
    var composition = await loadComposition('example/assets/LottieLogo1.json');
    expect(composition.frameRate, 30);

    await tester.pumpWidget(Lottie(composition: composition));
    await tester.pump();

    // After each pumped frame the ticker must be waiting on its delay timer,
    // not on a vsync callback: a regular ticker re-arms a frame callback
    // immediately after every tick, which would keep `hasScheduledFrame` true
    // and the engine pumping at display rate.
    for (var i = 0; i < 60; i++) {
      await tester.pump(vsync);
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
  });

  testWidgets('frame rates at or above the display rate are not throttled', (
    tester,
  ) async {
    var composition = await loadComposition('example/assets/LottieLogo1.json');

    await tester.pumpWidget(
      Lottie(composition: composition, frameRate: const FrameRate(60)),
    );
    await tester.pump();

    // A 60fps target on a 60Hz display must tick on every vsync like a plain
    // ticker (the delay clamps to zero): arming a timer instead would make
    // every tick miss its vsync and halve the effective frame rate.
    for (var i = 0; i < 60; i++) {
      await tester.pump(vsync);
      expect(tester.binding.hasScheduledFrame, isTrue);
    }
  });

  testWidgets('throttled animation stays wall-clock correct', (tester) async {
    var composition = await loadComposition('example/assets/LottieLogo1.json');

    await tester.pumpWidget(Lottie(composition: composition, repeat: false));
    await tester.pump();

    // Pump 2 seconds of wall-clock time in vsync-sized steps. Even though the
    // ticker only fires ~30 times per second, elapsed time comes from frame
    // timestamps, so late ticks drop frames instead of slowing the animation.
    const steps = 120;
    for (var i = 0; i < steps; i++) {
      await tester.pump(vsync);
    }

    var progress = tester.widget<RawLottie>(find.byType(RawLottie)).progress;
    var expected =
        (vsync * steps).inMicroseconds / composition.duration.inMicroseconds;
    var oneFrame = 1 / composition.durationFrames;
    expect(progress, closeTo(expected, oneFrame * 3));
  });

  testWidgets('a composition frame rate that does not divide the display rate '
      'renders every frame in order', (tester) async {
    var composition = await loadComposition(
      'example/assets/battery_optimizations.json',
    );
    expect(composition.frameRate, 25);

    await tester.pumpWidget(Lottie(composition: composition));
    await tester.pump();

    // 25fps targets fall between 60Hz vsyncs. The delay timer must aim for
    // the vsync grid so that ticks never land before a composition-frame
    // boundary; otherwise the rebuild gate discards the tick and frames get
    // skipped. Collect the rendered frames over 2 simulated seconds and
    // check the sequence is consecutive (no skips) at ~25fps.
    var frames = <int>[];
    for (var i = 0; i < 120; i++) {
      await tester.pump(vsync);
      var progress = tester.widget<RawLottie>(find.byType(RawLottie)).progress;
      var frame = (progress * composition.durationFrames).round();
      if (frames.isEmpty || frames.last != frame) {
        frames.add(frame);
      }
    }

    expect(frames.length, greaterThan(45));
    expect(frames.length, lessThan(56));
    for (var i = 1; i < frames.length; i++) {
      expect(
        frames[i] - frames[i - 1],
        1,
        reason: 'skipped frame between ${frames[i - 1]} and ${frames[i]}',
      );
    }
  });

  testWidgets('TickerMode pauses the throttled animation', (tester) async {
    var composition = await loadComposition('example/assets/LottieLogo1.json');

    Widget build({required bool enabled}) => TickerMode(
      enabled: enabled,
      child: Lottie(composition: composition),
    );
    double progress() =>
        tester.widget<RawLottie>(find.byType(RawLottie)).progress;

    await tester.pumpWidget(build(enabled: true));
    for (var i = 0; i < 10; i++) {
      await tester.pump(vsync);
    }
    expect(progress(), greaterThan(0));

    await tester.pumpWidget(build(enabled: false));
    await tester.pump();
    var paused = progress();
    for (var i = 0; i < 10; i++) {
      await tester.pump(vsync);
    }
    expect(progress(), paused);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(build(enabled: true));
    for (var i = 0; i < 10; i++) {
      await tester.pump(vsync);
    }
    expect(progress(), greaterThan(paused));
  });

  testWidgets('mounting under a disabled TickerMode schedules no frame', (
    tester,
  ) async {
    var composition = await loadComposition('example/assets/LottieLogo1.json');

    await tester.pumpWidget(
      TickerMode(enabled: false, child: Lottie(composition: composition)),
    );

    // The ambient TickerMode must be applied before the auto-animation
    // starts: a widget mounted on a covered page must not request any engine
    // frame at all.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('throttle is disabled under flutter test unless opted in, '
      'so pumpAndSettle completes the animation', (tester) async {
    debugThrottleAnimationsInTests = false;
    var composition = await loadComposition('example/assets/LottieLogo1.json');

    await tester.pumpWidget(Lottie(composition: composition, repeat: false));
    await tester.pumpAndSettle();

    var progress = tester.widget<RawLottie>(find.byType(RawLottie)).progress;
    expect(progress, 1.0);
  });
}
