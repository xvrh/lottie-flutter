import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// The vsync ticker notifies every display frame, but the widget should only
/// rebuild when the frame-rate-rounded progress actually changes, so a 30fps
/// composition on a 60Hz display rebuilds ~30 times/second, not 60.
void main() {
  testWidgets('rebuilds are throttled to the composition frame rate', (
    tester,
  ) async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/LottieLogo1.json').readAsBytesSync(),
    );
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
      await tester.pump(const Duration(milliseconds: 1000 ~/ 60));
    }

    // Without throttling this would be 60 (one rebuild per vsync).
    expect(builds, lessThan(40));
    expect(builds, greaterThan(20));
  });

  testWidgets('FrameRate.max rebuilds every frame', (tester) async {
    var composition = await LottieComposition.fromBytes(
      File('example/assets/LottieLogo1.json').readAsBytesSync(),
    );

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
      await tester.pump(const Duration(milliseconds: 1000 ~/ 60));
    }

    expect(builds, greaterThan(50));
  });
}
