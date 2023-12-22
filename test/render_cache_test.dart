import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('Golden renderCache', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
        File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync());

    var size = const Size(500, 400);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(RawLottie(
        progress: 0.5,
        composition: composition,
        renderCache: RenderCache.raster));
    expect(RenderCache.raster.store.imageCount, 1);

    await expectLater(find.byType(RawLottie),
        matchesGoldenFile('goldens/enable_render_cache.png'));
  });

  testWidgets('Enable render cache', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
        File('example/assets/lottiefiles/bell.json').readAsBytesSync());

    var widget = _boilerplate(
      ListView(
        children: [
          for (var i = 0; i < 2; i++)
            Lottie(
              composition: composition,
              renderCache: RenderCache.raster,
              height: 100,
            ),
        ],
      ),
    );

    await tester.pumpWidget(widget);
    expect(RenderCache.raster.store.imageCount, 1);
    expect(RenderCache.raster.store.handles.length, 2);
    expect(RenderCache.raster.store.entries.length, 1);
    var image =
        RenderCache.raster.store.entries.values.first.images.values.first;
    await tester.pumpWidget(widget);
    expect(RenderCache.raster.store.imageCount, 1);
    var image2 =
        RenderCache.raster.store.entries.values.first.images.values.first;
    expect(image, image2);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(widget);
    expect(RenderCache.raster.store.imageCount, 2);
    await tester.pumpWidget(Container());
    expect(RenderCache.raster.store.imageCount, 0);
    await tester.pumpWidget(widget);
    expect(RenderCache.raster.store.imageCount, 1);
  });

  testWidgets('Enable render cache', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
        File('example/assets/lottiefiles/bell.json').readAsBytesSync());

    var widget = _boilerplate(
      ListView(
        children: [
          for (var i = 0; i < 2; i++)
            RawLottie(
              composition: composition,
              renderCache: RenderCache.raster,
              height: 100,
              progress: 0,
            ),
        ],
      ),
    );

    await tester.pumpWidget(widget);
  });

  testWidgets('Cache cleared when a property change', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
        File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync());

    await tester.pumpWidget(RawLottie(
        progress: 0.5,
        composition: composition,
        frameRate: const FrameRate(60),
        renderCache: RenderCache.raster));
    await tester.pumpWidget(RawLottie(
        progress: 0.6,
        composition: composition,
        frameRate: const FrameRate(60),
        renderCache: RenderCache.raster));
    expect(RenderCache.raster.store.imageCount, 2);

    await tester.pumpWidget(RawLottie(
        progress: 0.7,
        composition: composition,
        frameRate: const FrameRate(30),
        renderCache: RenderCache.raster));
    expect(RenderCache.raster.store.imageCount, 1);
  });

  testWidgets('Cache cleared when a delegate change', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
        File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync());

    String textCallback(String s) => s;
    String textCallback2(String s) => s;
    await tester.pumpWidget(RawLottie(
        progress: 0.5,
        composition: composition,
        delegates: LottieDelegates(text: textCallback),
        renderCache: RenderCache.raster));
    await tester.pumpWidget(RawLottie(
        progress: 0.6,
        composition: composition,
        delegates: LottieDelegates(text: textCallback),
        renderCache: RenderCache.raster));
    expect(RenderCache.raster.store.imageCount, 2);

    await tester.pumpWidget(RawLottie(
        progress: 0.7,
        composition: composition,
        delegates: LottieDelegates(text: textCallback2),
        renderCache: RenderCache.raster));
    expect(RenderCache.raster.store.imageCount, 1);
  });

  testWidgets('Cache cleared when a delegate value change', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
        File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync());

    await tester.pumpWidget(RawLottie(
        progress: 0.5,
        composition: composition,
        delegates: LottieDelegates(values: [
          ValueDelegate.color(['*'], value: Colors.red),
        ]),
        renderCache: RenderCache.raster));
    await tester.pumpWidget(RawLottie(
        progress: 0.6,
        composition: composition,
        delegates: LottieDelegates(values: [
          ValueDelegate.color(['*'], value: Colors.red),
        ]),
        renderCache: RenderCache.raster));
    expect(RenderCache.raster.store.imageCount, 2);

    await tester.pumpWidget(RawLottie(
        progress: 0.7,
        composition: composition,
        delegates: LottieDelegates(values: [
          ValueDelegate.color(['*'], value: Colors.blue),
        ]),
        renderCache: RenderCache.raster));
    expect(RenderCache.raster.store.imageCount, 1);
  });

  testWidgets('2 widgets with same animation share cache', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
        File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync());

    await tester.pumpWidget(Column(
      children: [
        RawLottie(
          progress: 0.5,
          composition: composition,
          renderCache: RenderCache.raster,
          height: 50,
        ),
        RawLottie(
          progress: 0.5,
          composition: composition,
          renderCache: RenderCache.raster,
          height: 50,
        ),
      ],
    ));
    expect(RenderCache.raster.store.imageCount, 1);

    await tester.pumpWidget(Column(
      children: [
        RawLottie(
          progress: 0.6,
          composition: composition,
          renderCache: RenderCache.raster,
          height: 50,
        ),
        RawLottie(
          progress: 0.5,
          composition: composition,
          renderCache: RenderCache.raster,
          height: 50,
        ),
      ],
    ));
    expect(RenderCache.raster.store.imageCount, 2);

    await tester.pumpWidget(Column(
      children: [
        RawLottie(
          progress: 0.6,
          composition: composition,
          renderCache: RenderCache.raster,
          height: 50,
        ),
        RawLottie(
          progress: 0.6,
          composition: composition,
          renderCache: RenderCache.raster,
          height: 50,
        ),
      ],
    ));
    expect(RenderCache.raster.store.imageCount, 2);
  });
}

Widget _boilerplate(Widget widget) {
  return MaterialApp(
    home: Scaffold(
      body: widget,
    ),
  );
}
