import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('Golden renderCache', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
      File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync(),
    );

    var size = const Size(500, 400);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RawLottie(
        progress: 0.5,
        composition: composition,
        renderCache: RenderCache.raster,
      ),
    );
    expect(RenderCache.raster.store.imageCount, 1);

    await expectLater(
      find.byType(RawLottie),
      matchesGoldenFile('goldens/enable_render_cache.png'),
    );
  });

  // Regression test: BoxFit.cover on a non-matching aspect ratio crops the
  // composition, producing a sourceRect with a non-zero left/top offset
  // (the offset and its sign depend on alignment). The cached (raster and
  // drawingCommands) render paths must crop to the exact same region as the
  // uncached path, for every alignment.
  //
  // The composition is square (300x300), so a wide destination only crops
  // vertically (exercising top/center/bottom) while a tall destination only
  // crops horizontally (exercising left/center/right) - both are needed to
  // cover every alignment's offset.
  //
  // Each alignment gets its own test/golden file (rather than one combined
  // grid image): CacheKey (lib/src/render_cache/key.dart) does not factor in
  // sourceRect/alignment/fit, only (composition, size, config, delegates), so
  // multiple simultaneously-mounted RawLottie of the same pixel size but
  // different alignment would incorrectly share one raster cache entry -
  // that's a separate, real bug (see discussion), not something this test is
  // meant to cover.
  var alignments = <String, Alignment>{
    'topLeft': Alignment.topLeft,
    'topCenter': Alignment.topCenter,
    'topRight': Alignment.topRight,
    'centerLeft': Alignment.centerLeft,
    'center': Alignment.center,
    'centerRight': Alignment.centerRight,
    'bottomLeft': Alignment.bottomLeft,
    'bottomCenter': Alignment.bottomCenter,
    'bottomRight': Alignment.bottomRight,
  };
  var destinationSizes = <String, Size>{
    'wide': const Size(500, 200),
    'tall': const Size(200, 500),
  };
  for (var MapEntry(key: sizeName, value: destinationSize)
      in destinationSizes.entries) {
    for (var MapEntry(key: alignmentName, value: alignment)
        in alignments.entries) {
      testWidgets(
        'Golden renderCache with cropped fit ($sizeName, $alignmentName)',
        (tester) async {
          var composition = LottieComposition.parseJsonBytes(
            File(
              'example/assets/lottiefiles/a_mountain.json',
            ).readAsBytesSync(),
          );

          tester.view.physicalSize = destinationSize;
          tester.view.devicePixelRatio = 1.0;

          var goldenFile = 'goldens/cropped_fit/${sizeName}_$alignmentName.png';

          await tester.pumpWidget(
            RawLottie(
              progress: 0.5,
              composition: composition,
              fit: BoxFit.cover,
              alignment: alignment,
            ),
          );
          await expectLater(
            find.byType(RawLottie),
            matchesGoldenFile(goldenFile),
          );

          await tester.pumpWidget(
            RawLottie(
              progress: 0.5,
              composition: composition,
              fit: BoxFit.cover,
              alignment: alignment,
              renderCache: RenderCache.raster,
            ),
          );
          await expectLater(
            find.byType(RawLottie),
            matchesGoldenFile(goldenFile),
          );

          await tester.pumpWidget(
            RawLottie(
              progress: 0.5,
              composition: composition,
              fit: BoxFit.cover,
              alignment: alignment,
              renderCache: RenderCache.drawingCommands,
            ),
          );
          await expectLater(
            find.byType(RawLottie),
            matchesGoldenFile(goldenFile),
          );
        },
      );
    }
  }

  testWidgets(
    'Raster cache does not confuse two widgets sharing composition/size but different alignment',
    (tester) async {
      // Regression test: CacheKey (lib/src/render_cache/key.dart) is built
      // from (composition, size, config, delegates) only - it doesn't
      // account for sourceRect/alignment/fit. Two RawLottie widgets that
      // share a composition and end up with the same on-screen pixel size,
      // but crop the composition differently (here: opposite alignment),
      // must not end up sharing (and thus corrupting) the same raster cache
      // entry when mounted at the same time.
      var composition = LottieComposition.parseJsonBytes(
        File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync(),
      );

      const cellSize = Size(200, 500);
      tester.view.physicalSize = Size(cellSize.width * 2, cellSize.height);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: const Key('topLeft'),
                child: SizedBox(
                  width: cellSize.width,
                  height: cellSize.height,
                  child: RawLottie(
                    progress: 0.5,
                    composition: composition,
                    fit: BoxFit.cover,
                    alignment: Alignment.topLeft,
                    renderCache: RenderCache.raster,
                  ),
                ),
              ),
              RepaintBoundary(
                key: const Key('bottomRight'),
                child: SizedBox(
                  width: cellSize.width,
                  height: cellSize.height,
                  child: RawLottie(
                    progress: 0.5,
                    composition: composition,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomRight,
                    renderCache: RenderCache.raster,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Both widgets have the exact same composition/size/config/delegates,
      // so with the buggy CacheKey they'd incorrectly share one entry.
      await expectLater(
        find.byKey(const Key('topLeft')),
        matchesGoldenFile('goldens/cropped_fit/tall_topLeft.png'),
      );
      await expectLater(
        find.byKey(const Key('bottomRight')),
        matchesGoldenFile('goldens/cropped_fit/tall_bottomRight.png'),
      );
    },
  );

  testWidgets('Enable render cache', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
      File('example/assets/lottiefiles/bell.json').readAsBytesSync(),
    );

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
      File('example/assets/lottiefiles/bell.json').readAsBytesSync(),
    );

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
      File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync(),
    );

    await tester.pumpWidget(
      RawLottie(
        progress: 0.5,
        composition: composition,
        frameRate: const FrameRate(60),
        renderCache: RenderCache.raster,
      ),
    );
    await tester.pumpWidget(
      RawLottie(
        progress: 0.6,
        composition: composition,
        frameRate: const FrameRate(60),
        renderCache: RenderCache.raster,
      ),
    );
    expect(RenderCache.raster.store.imageCount, 2);

    await tester.pumpWidget(
      RawLottie(
        progress: 0.7,
        composition: composition,
        frameRate: const FrameRate(30),
        renderCache: RenderCache.raster,
      ),
    );
    expect(RenderCache.raster.store.imageCount, 1);
  });

  testWidgets('Cache cleared when a delegate change', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
      File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync(),
    );

    String textCallback(String s) => s;
    String textCallback2(String s) => s;
    await tester.pumpWidget(
      RawLottie(
        progress: 0.5,
        composition: composition,
        delegates: LottieDelegates(text: textCallback),
        renderCache: RenderCache.raster,
      ),
    );
    await tester.pumpWidget(
      RawLottie(
        progress: 0.6,
        composition: composition,
        delegates: LottieDelegates(text: textCallback),
        renderCache: RenderCache.raster,
      ),
    );
    expect(RenderCache.raster.store.imageCount, 2);

    await tester.pumpWidget(
      RawLottie(
        progress: 0.7,
        composition: composition,
        delegates: LottieDelegates(text: textCallback2),
        renderCache: RenderCache.raster,
      ),
    );
    expect(RenderCache.raster.store.imageCount, 1);
  });

  testWidgets('Cache cleared when a delegate value change', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
      File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync(),
    );

    await tester.pumpWidget(
      RawLottie(
        progress: 0.5,
        composition: composition,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(['*'], value: Colors.red),
          ],
        ),
        renderCache: RenderCache.raster,
      ),
    );
    await tester.pumpWidget(
      RawLottie(
        progress: 0.6,
        composition: composition,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(['*'], value: Colors.red),
          ],
        ),
        renderCache: RenderCache.raster,
      ),
    );
    expect(RenderCache.raster.store.imageCount, 2);

    await tester.pumpWidget(
      RawLottie(
        progress: 0.7,
        composition: composition,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(['*'], value: Colors.blue),
          ],
        ),
        renderCache: RenderCache.raster,
      ),
    );
    expect(RenderCache.raster.store.imageCount, 1);
  });

  testWidgets('2 widgets with same animation share cache', (tester) async {
    var composition = LottieComposition.parseJsonBytes(
      File('example/assets/lottiefiles/a_mountain.json').readAsBytesSync(),
    );

    await tester.pumpWidget(
      Column(
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
      ),
    );
    expect(RenderCache.raster.store.imageCount, 1);

    await tester.pumpWidget(
      Column(
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
      ),
    );
    expect(RenderCache.raster.store.imageCount, 2);

    await tester.pumpWidget(
      Column(
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
      ),
    );
    expect(RenderCache.raster.store.imageCount, 2);
  });
}

Widget _boilerplate(Widget widget) {
  return MaterialApp(home: Scaffold(body: widget));
}
