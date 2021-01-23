import 'dart:ui' as ui;
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_image.dart';
import 'lottie_provider.dart';
import 'provider_io.dart' if (dart.library.html) 'provider_web.dart' as io;

class FileLottie extends LottieProvider {
  FileLottie(this.file, {LottieImageProviderFactory? imageProviderFactory})
      : super(imageProviderFactory: imageProviderFactory);

  final Object /*io.File|html.File*/ file;

  @override
  Future<LottieComposition> load() async {
    var cacheKey = 'file-${io.filePath(file)}';
    return sharedLottieCache.putIfAbsent(cacheKey, () async {
      var bytes = await io.loadFile(file);
      var composition = await LottieComposition.fromBytes(bytes,
          name: p.basenameWithoutExtension(io.filePath(file)));

      for (var image in composition.images.values) {
        image.loadedImage ??= await _loadImage(composition, image);
      }

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
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is FileLottie && other.file == file;
  }

  @override
  int get hashCode => file.hashCode;

  @override
  String toString() => '$runtimeType(file: ${io.filePath(file)})';
}
