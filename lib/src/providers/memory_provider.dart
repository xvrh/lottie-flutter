import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_image.dart';
import 'lottie_provider.dart';

@immutable
class MemoryLottie extends LottieProvider {
  MemoryLottie(this.bytes, {
    super.imageProviderFactory,
    super.decoder, 
    super.activeAnimationId,
  });

  final Uint8List bytes;

  @override
  Future<LottieComposition> load({BuildContext? context}) {
    return sharedLottieCache.putIfAbsent(this, () async {
      var composition =
          await LottieComposition.fromBytes(bytes, decoder: decoder, activeAnimationId: activeAnimationId);
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

    //TODO(xha): compare bytes content
    return other is MemoryLottie && other.bytes == bytes;
  }

  @override
  int get hashCode => bytes.hashCode;

  @override
  String toString() => '$runtimeType(bytes: ${bytes.length})';
}
