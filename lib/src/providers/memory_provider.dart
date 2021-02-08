import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_image.dart';
import 'lottie_provider.dart';

class MemoryLottie extends LottieProvider {
  MemoryLottie(this.bytes, {LottieImageProviderFactory? imageProviderFactory})
      : super(imageProviderFactory: imageProviderFactory);

  final Uint8List bytes;

  @override
  Future<LottieComposition> load() async {
    // TODO(xha): hash the list content
    var cacheKey = 'memory-${bytes.hashCode}-${bytes.lengthInBytes}';
    return sharedLottieCache.putIfAbsent(cacheKey, () async {
      var composition = await LottieComposition.fromBytes(bytes,
          imageProviderFactory: imageProviderFactory);
      for (var image in composition.images.values) {
        image.loadedImage ??= await _loadImage(composition, image);
      }

      return composition;
    });
  }

  Future<ui.Image?> _loadImage(
      LottieComposition composition, LottieImageAsset lottieImage) {
    var imageProvider = getImageProvider(lottieImage);

    imageProvider ??=
        AssetImage(p.join(lottieImage.dirName, lottieImage.fileName));

    return loadImage(composition, lottieImage, imageProvider);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is MemoryLottie && other.bytes == bytes;
  }

  @override
  int get hashCode => bytes.hashCode;

  @override
  String toString() => '$runtimeType(bytes: ${bytes.length})';
}
