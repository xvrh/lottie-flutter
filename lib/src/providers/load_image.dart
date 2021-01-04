import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import '../composition.dart';
import '../lottie_image_asset.dart';

typedef LottieImageProviderFactory = ImageProvider Function(LottieImageAsset);

Future<ui.Image?> loadImage(LottieComposition composition,
    LottieImageAsset lottieImage, ImageProvider provider) {
  var completer = Completer<ui.Image?>();
  var imageStream = provider.resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener((image, synchronousLoaded) {
    imageStream.removeListener(listener);

    completer.complete(image.image);
  }, onError: (dynamic e, __) {
    imageStream.removeListener(listener);

    composition.addWarning('Failed to load image ${lottieImage.id}: $e');
    completer.complete();
  });
  imageStream.addListener(listener);

  return completer.future;
}

ImageProvider? fromDataUri(String filePath) {
  if (filePath.startsWith('data:')) {
    return MemoryImage(Uri.parse(filePath).data!.contentAsBytes());
  }
  return null;
}
