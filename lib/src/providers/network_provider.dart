import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_image.dart';
import 'lottie_provider.dart';
import 'provider_io.dart' if (dart.library.html) 'provider_web.dart' as network;

@immutable
class NetworkLottie extends LottieProvider {
  NetworkLottie(this.url,
      {this.headers, super.imageProviderFactory, super.decoder});

  final String url;
  final Map<String, String>? headers;

  @override
  Future<LottieComposition> load({BuildContext? context}) {
    return sharedLottieCache.putIfAbsent(this, () async {
      var resolved = Uri.base.resolve(url);
      var bytes = await network.loadHttp(resolved, headers: headers);

      var composition =
          await LottieComposition.fromBytes(bytes, decoder: decoder);

      for (var image in composition.images.values) {
        image.loadedImage ??= await _loadImage(resolved, composition, image);
      }

      return composition;
    });
  }

  Future<ui.Image?> _loadImage(Uri jsonUri, LottieComposition composition,
      LottieImageAsset lottieImage) {
    var imageProvider = getImageProvider(lottieImage);

    if (imageProvider == null) {
      var imageUrl = jsonUri
          .resolve(p.url.join(lottieImage.dirName, lottieImage.fileName));
      imageProvider = NetworkImage(imageUrl.toString());
    }

    return loadImage(composition, lottieImage, imageProvider);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is NetworkLottie &&
        other.url == url &&
        other.decoder == decoder;
  }

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => '$runtimeType(url: $url)';
}
