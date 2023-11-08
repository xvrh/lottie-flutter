import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'utils.dart';

void main() {
  testWidgets('Can specify ImageProvider with zip file ', (tester) async {
    var size = const Size(500, 400);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    var callCount = 0;
    ImageProvider imageProviderFactory(LottieImageAsset image) {
      ++callCount;
      return FileImage(File('example/assets/Images/WeAccept/img_0.png'));
    }

    Future<LottieComposition?> decoder(List<int> bytes) {
      return LottieComposition.decodeZip(bytes,
          imageProviderFactory: imageProviderFactory);
    }

    var composition = (await tester.runAsync(() => FileLottie(
            File('example/assets/spinning_carrousel.zip'),
            imageProviderFactory: imageProviderFactory,
            decoder: decoder)
        .load()))!;

    await tester.pumpWidget(FilmStrip(composition, size: size));

    expect(callCount, 2);
    await expectLater(find.byType(FilmStrip),
        matchesGoldenFile('goldens/dynamic_image/zip_with_provider.png'));
  });

  testWidgets('Can specify image delegate', (tester) async {
    var size = const Size(500, 400);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    var image = await tester.runAsync(() async =>
        loadImage(FileImage(File('example/assets/Images/WeAccept/img_0.png'))));

    var composition = (await tester.runAsync(() async =>
        FileLottie(File('example/assets/spinning_carrousel.zip')).load()))!;

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
