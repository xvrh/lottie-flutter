import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_fonts.dart';
import 'load_image.dart';
import 'lottie_provider.dart';

@immutable
class AssetLottie extends LottieProvider {
  AssetLottie(
    this.assetName, {
    this.bundle,
    this.package,
    super.imageProviderFactory,
    super.decoder,
    super.backgroundLoading,
  });

  final String assetName;
  String get keyName =>
      package == null ? assetName : 'packages/$package/$assetName';

  final AssetBundle? bundle;

  final String? package;

  @override
  Future<LottieComposition> load({BuildContext? context}) {
    return sharedLottieCache.putIfAbsent(this, () async {
      final finalContext = context;
      final chosenBundle = bundle ??
          (finalContext != null
              ? DefaultAssetBundle.of(finalContext)
              : rootBundle);

      var data = await chosenBundle.load(keyName);

      LottieComposition composition;
      if (backgroundLoading) {
        composition =
            await compute(parseJsonBytes, (data.buffer.asUint8List(), decoder));
      } else {
        composition =
            await LottieComposition.fromByteData(data, decoder: decoder);
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

    if (imageProvider == null) {
      var imageAssetPath = p.url.join(
          p.dirname(assetName), lottieImage.dirName, lottieImage.fileName);
      imageProvider =
          AssetImage(imageAssetPath, bundle: bundle, package: package);
    }

    return loadImage(composition, lottieImage, imageProvider);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AssetLottie &&
        other.keyName == keyName &&
        other.bundle == bundle &&
        other.decoder == decoder;
  }

  @override
  int get hashCode => Object.hash(keyName, bundle);

  @override
  String toString() => '$runtimeType(bundle: $bundle, name: "$keyName")';
}
