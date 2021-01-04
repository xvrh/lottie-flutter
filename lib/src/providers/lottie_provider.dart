import 'package:flutter/cupertino.dart';
import '../../lottie.dart';
import 'load_image.dart';

abstract class LottieProvider {
  LottieProvider({this.imageProviderFactory});

  final LottieImageProviderFactory? imageProviderFactory;

  ImageProvider? getImageProvider(LottieImageAsset lottieImage) {
    var imageProvider = fromDataUri(lottieImage.fileName);
    if (imageProvider == null && imageProviderFactory != null) {
      imageProvider = imageProviderFactory!(lottieImage);
    }
    return imageProvider;
  }

  Future<LottieComposition> load();
}

class LottieCache {
  final int maximumSize;
  final _cache = <String, Future<LottieComposition>>{};

  LottieCache({int? maximumSize}) : maximumSize = maximumSize ?? 1000;

  Future<LottieComposition> putIfAbsent(
      String key, Future<LottieComposition> Function() load) {
    var composition = _cache[key];
    if (composition != null) {
      // Remove it so that we add it in front of the cache to prevent evicted
      _cache.remove(key);
    } else {
      composition = load();
    }

    _cache[key] = composition;

    _checkCacheSize();

    return composition;
  }

  void _checkCacheSize() {
    while (_cache.length > maximumSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  void clear() {
    _cache.clear();
  }
}

final sharedLottieCache = LottieCache();
