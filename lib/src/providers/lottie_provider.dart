import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../../lottie.dart';
import 'load_image.dart';

abstract class LottieProvider {
  LottieProvider({
    this.imageProviderFactory,
    this.decoder,
    bool? backgroundLoading,
  }) : backgroundLoading = backgroundLoading ?? false;

  final LottieImageProviderFactory? imageProviderFactory;

  final LottieDecoder? decoder;

  final bool backgroundLoading;

  ImageProvider? getImageProvider(LottieImageAsset lottieImage) {
    var imageProvider = fromDataUri(lottieImage.fileName);
    if (imageProvider == null && imageProviderFactory != null) {
      imageProvider = imageProviderFactory!(lottieImage);
    }
    return imageProvider;
  }

  Future<LottieComposition> load({BuildContext? context});
}

Future<LottieComposition> parseJsonBytes(
    (Uint8List, LottieDecoder?) args) async {
  return LottieComposition.fromBytes(args.$1, decoder: args.$2);
}

class LottieCache {
  final Map<Object, Future<LottieComposition>> _pending =
      <Object, Future<LottieComposition>>{};
  final Map<Object, LottieComposition> _cache = <Object, LottieComposition>{};

  /// Maximum number of entries to store in the cache.
  ///
  /// Once this many entries have been cached, the least-recently-used entry is
  /// evicted when adding a new entry.
  int get maximumSize => _maximumSize;
  int _maximumSize = 1000;

  /// Changes the maximum cache size.
  ///
  /// If the new size is smaller than the current number of elements, the
  /// extraneous elements are evicted immediately. Setting this to zero and then
  /// returning it to its original value will therefore immediately clear the
  /// cache.
  set maximumSize(int value) {
    assert(value >= 0);
    if (value == maximumSize) {
      return;
    }
    _maximumSize = value;
    if (maximumSize == 0) {
      clear();
    } else {
      while (_cache.length > maximumSize) {
        _cache.remove(_cache.keys.first);
      }
    }
  }

  /// Evicts all entries from the cache.
  ///
  /// This is useful if, for instance, the root asset bundle has been updated
  /// and therefore new images must be obtained.
  void clear() {
    _cache.clear();
  }

  /// Evicts a single entry from the cache, returning true if successful.
  bool evict(Object key) {
    return _cache.remove(key) != null;
  }

  /// Returns the previously cached [LottieComposition] for the given key, if available;
  /// if not, calls the given callback to obtain it first. In either case, the
  /// key is moved to the "most recently used" position.
  ///
  /// The arguments must not be null. The `loader` cannot return null.
  Future<LottieComposition> putIfAbsent(
    Object key,
    Future<LottieComposition> Function() loader,
  ) {
    var pendingResult = _pending[key];
    if (pendingResult != null) {
      return pendingResult;
    }

    var result = _cache[key];
    if (result != null) {
      // Remove the provider from the list so that we can put it back in below
      // and thus move it to the end of the list.
      _cache.remove(key);
    } else {
      if (_cache.length == maximumSize && maximumSize > 0) {
        _cache.remove(_cache.keys.first);
      }
      pendingResult = loader();
      _pending[key] = pendingResult;
      pendingResult.then<void>((LottieComposition data) {
        _pending.remove(key);
        _add(key, data);

        result = data; // in case it was a synchronous future.
      }).catchError((Object? e) {
        _pending.remove(key);
      });
    }
    if (result != null) {
      _add(key, result!);
      return SynchronousFuture<LottieComposition>(result!);
    }
    assert(_cache.length <= maximumSize);
    return pendingResult!;
  }

  void _add(Object key, LottieComposition result) {
    if (maximumSize > 0) {
      assert(_cache.length < maximumSize);
      _cache[key] = result;
    }
    assert(_cache.length <= maximumSize);
  }

  /// The number of entries in the cache.
  int get count => _cache.length;
}

final sharedLottieCache = LottieCache();
