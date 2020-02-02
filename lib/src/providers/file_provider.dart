import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_image.dart';
import 'lottie_provider.dart';

class FileLottie extends LottieProvider {
  FileLottie(this.file, {LottieImageProviderFactory imageProviderFactory})
      : super(imageProviderFactory: imageProviderFactory);

  final File file;

  @override
  Future<LottieComposition> load() async {
    var cacheKey = 'file-${file.path}';
    return sharedLottieCache.putIfAbsent(cacheKey, () async {
      var bytes = await file.readAsBytes();
      var composition = await LottieComposition.fromBytes(bytes);

      for (var image in composition.images.values) {
        image.loadedImage ??= await _loadImage(composition, image);
      }

      return composition;
    });
  }

  Future<ui.Image> _loadImage(
      LottieComposition composition, LottieImageAsset lottieImage) {
    var imageProvider = getImageProvider(lottieImage);

    if (imageProvider == null) {
      var imagePath = p.url.join(
          p.dirname(file.path), lottieImage.dirName, lottieImage.fileName);
      imageProvider = FileImage(File(imagePath));
    }

    return loadImage(composition, lottieImage, imageProvider);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is FileLottie && other.file == file;
  }

  @override
  int get hashCode => file.hashCode;

  @override
  String toString() => '$runtimeType(file: ${file.path})';
}
