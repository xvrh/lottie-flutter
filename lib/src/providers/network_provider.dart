import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_fonts.dart';
import 'load_image.dart';
import 'lottie_provider.dart';

@immutable
class NetworkLottie extends LottieProvider {
  NetworkLottie(
    this.url, {
    this.client,
    this.headers,
    super.imageProviderFactory,
    super.decoder,
    super.backgroundLoading,
  });

  final http.Client? client;
  final String url;
  final Map<String, String>? headers;

  @override
  Future<LottieComposition> load({BuildContext? context}) {
    return sharedLottieCache.putIfAbsent(this, () async {
      var resolved = Uri.base.resolve(url);

      var client = this.client ?? http.Client();
      try {
        var bytes = await client.readBytes(resolved, headers: headers);

        LottieComposition composition;
        if (backgroundLoading) {
          composition = await compute(parseJsonBytes, (bytes, decoder));
        } else {
          composition =
              await LottieComposition.fromBytes(bytes, decoder: decoder);
        }

        for (var image in composition.images.values) {
          image.loadedImage ??= await _loadImage(resolved, composition, image);
        }

        await ensureLoadedFonts(composition);

        return composition;
      } finally {
        if (this.client == null) {
          client.close();
        }
      }
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
  bool operator ==(Object other) {
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
