import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_image.dart';
import 'lottie_provider.dart';

class NetworkLottie extends LottieProvider {
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  NetworkLottie(this.url,
      {this.headers, LottieImageProviderFactory imageProviderFactory})
      : super(imageProviderFactory: imageProviderFactory);

  final String url;
  final Map<String, String> headers;

  @override
  Future<LottieComposition> load() async {
    var cacheKey = 'network-$url';
    return sharedLottieCache.putIfAbsent(cacheKey, () async {
      var resolved = Uri.base.resolve(url);
      var request = await _sharedHttpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
            'Http error. Status code: ${response.statusCode} for $resolved');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.lengthInBytes == 0) {
        throw Exception('NetworkImage is an empty file: $resolved');
      }

      var composition = await LottieComposition.fromBytes(bytes);

      for (var image in composition.images.values) {
        image.loadedImage ??= await _loadImage(resolved, composition, image);
      }

      return composition;
    });
  }

  Future<ui.Image> _loadImage(Uri jsonUri, LottieComposition composition,
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
    return other is NetworkLottie && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => '$runtimeType(url: $url)';
}
