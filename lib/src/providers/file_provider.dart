import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_fonts.dart';
import 'load_image.dart';
import 'lottie_provider.dart';
import 'provider_io.dart' if (dart.library.html) 'provider_web.dart' as io;

@immutable
class FileLottie extends LottieProvider {
  FileLottie(
    this.file, {
    super.imageProviderFactory,
    super.decoder,
    super.backgroundLoading,
  });

  final Object /*io.File|html.File*/ file;

  @override
  Future<LottieComposition> load({BuildContext? context}) {
    return sharedLottieCache.putIfAbsent(this, () async {
      LottieComposition composition;
      var args = (file, decoder);
      if (backgroundLoading) {
        composition = await compute(loadFileAndParse, args);
      } else {
        composition = await loadFileAndParse(args);
      }

      for (var image in composition.images.values) {
        image.loadedImage ??= await _loadImage(composition, image);
      }

      await ensureLoadedFonts(composition);

      return composition;
    });
  }

  Future<ui.Image?> _loadImage(
      LottieComposition composition, LottieImageAsset lottieImage) {
    var imageProvider = getImageProvider(lottieImage);

    imageProvider ??= io.loadImageForFile(file, lottieImage);

    return loadImage(composition, lottieImage, imageProvider);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is FileLottie && io.areFilesEqual(file, other.file);
  }

  @override
  int get hashCode => file.hashCode;

  @override
  String toString() => '$runtimeType(file: ${io.filePath(file)})';
}

Future<LottieComposition> loadFileAndParse(
    (Object, LottieDecoder?) args) async {
  var bytes = await io.loadFile(args.$1);
  return await LottieComposition.fromBytes(bytes, decoder: args.$2);
}
