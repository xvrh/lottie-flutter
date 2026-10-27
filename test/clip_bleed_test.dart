import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  // A 100x100 composition covered by a 300x300 solid that also runs past its
  // bounds on every side.
  var composition = LottieComposition.parseJsonBytes(
    '''
{"v": "5.5.2", "fr": 30, "ip": 0, "op": 30, "w": 100, "h": 100, "layers": [
  {"ty": 1, "ind": 1, "sw": 300, "sh": 300, "sc": "#00ff00", "ip": 0, "op": 30, "st": 0,
   "ks": {"p": {"a": 0, "k": [-100, -100, 0]}}}
]}'''
        .codeUnits,
  );

  var cases = <(BoxFit, Size)>[
    (BoxFit.contain, const Size(40, 40)),
    (BoxFit.cover, const Size(100, 40)),
    (BoxFit.cover, const Size(40, 100)),
    (BoxFit.fitWidth, const Size(100, 40)),
    (BoxFit.fitHeight, const Size(40, 100)),
    (BoxFit.none, const Size(100, 40)),
  ];
  var renderCaches = <String, RenderCache?>{
    'no cache': null,
    'raster': RenderCache.raster,
    'drawingCommands': RenderCache.drawingCommands,
  };

  for (var (fit, size) in cases) {
    for (var MapEntry(key: cacheName, value: renderCache)
        in renderCaches.entries) {
      testWidgets(
        '$fit in a $size box paints nothing outside it ($cacheName)',
        (tester) async {
          tester.view.physicalSize = const Size(100, 100);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            RepaintBoundary(
              child: Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: RawLottie(
                    composition: composition,
                    progress: 0,
                    fit: fit,
                    renderCache: renderCache,
                  ),
                ),
              ),
            ),
          );

          var boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byType(RepaintBoundary).first,
          );
          var pixels = (await tester.runAsync(() async {
            var image = await boundary.toImage();
            return image.toByteData();
          }))!;
          int alphaAt(int x, int y) => pixels.getUint8((y * 100 + x) * 4 + 3);

          expect(alphaAt(50, 50), 255);
          for (var (x, y) in [(5, 5), (95, 5), (5, 95), (95, 95)]) {
            expect(
              alphaAt(x, y),
              0,
              reason: 'Pixel ($x, $y) is outside the box',
            );
          }
        },
      );
    }
  }
}
