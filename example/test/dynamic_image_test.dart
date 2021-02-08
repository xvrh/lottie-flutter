import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'utils.dart';

void main() {
  testWidgets('Can specify ImageProvider with zip file ', (tester) async {
    var size = Size(500, 400);
    tester.binding.window.physicalSizeTestValue = size;
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    var callCount = 0;
    LottieImageProviderFactory imageProviderFactory = (image) {
      ++callCount;
      return FileImage(File('assets/Images/WeAccept/img_0.png'));
    };

    var composition = (await tester.runAsync(() => FileLottie(
            File('assets/spinning_carrousel.zip'),
            imageProviderFactory: imageProviderFactory)
        .load()))!;

    await tester.pumpWidget(FilmStrip(composition, size: size));

    expect(callCount, 2);
    await expectLater(find.byType(FilmStrip),
        matchesGoldenFile('goldens/dynamic_image/zip_with_provider.png'));
  });

  testWidgets('Can specify image delegate', (tester) async {
    var size = Size(500, 400);
    tester.binding.window.physicalSizeTestValue = size;
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    var image = await tester.runAsync(
        () => loadImage(FileImage(File('assets/Images/WeAccept/img_0.png'))));

    var composition = (await tester.runAsync(
        () => FileLottie(File('assets/spinning_carrousel.zip')).load()))!;

    var delegates = LottieDelegates(image: (composition, asset) {
      return image;
    });
    await tester.pumpWidget(FilmStrip(
      composition,
      size: size,
      delegates: delegates,
    ));

    await expectLater(find.byType(FilmStrip),
        matchesGoldenFile('goldens/dynamic_image/delegate.png'));
  });
}

Future<ui.Image?> loadImage(ImageProvider provider) {
  var completer = Completer<ui.Image?>();
  var imageStream = provider.resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener((image, synchronousLoaded) {
    imageStream.removeListener(listener);

    completer.complete(image.image);
  }, onError: (dynamic e, __) {
    imageStream.removeListener(listener);

    completer.complete();
  });
  imageStream.addListener(listener);

  return completer.future;
}
