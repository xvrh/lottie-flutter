import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_fonts.dart';
import 'load_image.dart';
import 'lottie_provider.dart';

@immutable
class FileLottie extends LottieProvider {
  FileLottie(
    Object file, {
    super.imageProviderFactory,
    super.decoder,
    super.backgroundLoading,
  })  : file = file as io.File,
        assert(
          !kIsWeb,
          'Lottie.file is not supported on Flutter Web. '
          'Consider using either Lottie.asset or Lottie.network instead.',
        );

  final io.File file;

  @override
  Future<LottieComposition> load({BuildContext? context}) {
    return sharedLottieCache.putIfAbsent(this, () async {
      LottieComposition composition;
      var args = (file, decoder);
      if (backgroundLoading) {
        composition = await compute(_loadFileAndParse, args);
      } else {
        composition = await _loadFileAndParse(args);
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

    var imagePath = p.url
        .join(p.dirname(file.path), lottieImage.dirName, lottieImage.fileName);
    imageProvider ??= FileImage(io.File(imagePath));

    return loadImage(composition, lottieImage, imageProvider);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is FileLottie && file.path == other.file.path;
  }

  @override
  int get hashCode => file.hashCode;

  @override
  String toString() => '$runtimeType(file: ${file.path})';
}

Future<LottieComposition> _loadFileAndParse(
    (io.File, LottieDecoder?) args) async {
  var bytes = await args.$1.readAsBytes();
  return await LottieComposition.fromBytes(bytes, decoder: args.$2);
}
