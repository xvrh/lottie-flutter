// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../lottie.dart';

const int _kDefaultSize = 1000;
const int _kDefaultSizeBytes = 100 << 20; // 100 MiB

class LottieCache {
  final Map<Object, Future<LottieComposition>> _pendingLotties =
      <Object, Future<LottieComposition>>{};
  final Map<Object, _CachedLottie> _cache = <Object, _CachedLottie>{};

  /// Maximum number of entries to store in the cache.
  ///
  /// Once this many entries have been cached, the least-recently-used entry is
  /// evicted when adding a new entry.
  int get maximumSize => _maximumSize;
  int _maximumSize = _kDefaultSize;

  /// Changes the maximum cache size.
  ///
  /// If the new size is smaller than the current number of elements, the
  /// extraneous elements are evicted immediately. Setting this to zero and then
  /// returning it to its original value will therefore immediately clear the
  /// cache.
  set maximumSize(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == maximumSize) return;
    _maximumSize = value;
    if (maximumSize == 0) {
      clear();
    } else {
      _checkCacheSize();
    }
  }

  /// The current number of cached entries.
  int get currentSize => _cache.length;

  /// Maximum size of entries to store in the cache in bytes.
  ///
  /// Once more than this amount of bytes have been cached, the
  /// least-recently-used entry is evicted until there are fewer than the
  /// maximum bytes.
  int get maximumSizeBytes => _maximumSizeBytes;
  int _maximumSizeBytes = _kDefaultSizeBytes;

  /// Changes the maximum cache bytes.
  ///
  /// If the new size is smaller than the current size in bytes, the
  /// extraneous elements are evicted immediately. Setting this to zero and then
  /// returning it to its original value will therefore immediately clear the
  /// cache.
  set maximumSizeBytes(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == _maximumSizeBytes) return;
    _maximumSizeBytes = value;
    if (_maximumSizeBytes == 0) {
      clear();
    } else {
      _checkCacheSize();
    }
  }

  /// The current size of cached entries in bytes.
  int get currentSizeBytes => _currentSizeBytes;
  int _currentSizeBytes = 0;

  /// Evicts all entries from the cache.
  ///
  /// This is useful if, for instance, the root asset bundle has been updated
  /// and therefore new images must be obtained.
  ///
  /// Images which have not finished loading yet will not be removed from the
  /// cache, and when they complete they will be inserted as normal.
  void clear() {
    _cache.clear();
    _currentSizeBytes = 0;
  }

  /// Evicts a single entry from the cache, returning true if successful.
  /// Pending images waiting for completion are removed as well, returning true if successful.
  ///
  /// When a pending image is removed the listener on it is removed as well to prevent
  /// it from adding itself to the cache if it eventually completes.
  ///
  /// The [key] must be equal to an object used to cache an image in
  /// [ImageCache.putIfAbsent].
  ///
  /// If the key is not immediately available, as is common, consider using
  /// [ImageProvider.evict] to call this method indirectly instead.
  ///
  /// See also:
  ///
  ///  * [ImageProvider], for providing images to the [Image] widget.
  bool evict(Object key) {
    final image = _cache.remove(key);
    if (image != null) {
      _currentSizeBytes -= image.sizeBytes;
      return true;
    }
    return false;
  }

  /// Returns the previously cached [ImageStream] for the given key, if available;
  /// if not, calls the given callback to obtain it first. In either case, the
  /// key is moved to the "most recently used" position.
  ///
  /// The arguments must not be null. The `loader` cannot return null.
  ///
  /// In the event that the loader throws an exception, it will be caught only if
  /// `onError` is also provided. When an exception is caught resolving an image,
  /// no completers are cached and `null` is returned instead of a new
  /// completer.
  Future<LottieComposition> putIfAbsent(
      Object key, Future<LottieComposition> Function() loader) {
    assert(key != null);
    assert(loader != null);
    var result = _pendingLotties[key];
    // Nothing needs to be done because the image hasn't loaded yet.
    if (result != null) return result;
    // Remove the provider from the list so that we can move it to the
    // recently used position below.
    final image = _cache.remove(key);
    if (image != null) {
      _cache[key] = image;
      return Future.value(image.composition);
    }
    result = loader();

    LottieComposition listener(LottieComposition composition) {
      // Images that fail to load don't contribute to cache size.
      final imageSize = composition.jsonSize;
      final image = _CachedLottie(composition);
      // If the image is bigger than the maximum cache size, and the cache size
      // is not zero, then increase the cache size to the size of the image plus
      // some change.
      if (maximumSizeBytes > 0 && imageSize > maximumSizeBytes) {
        _maximumSizeBytes = imageSize + 1000;
      }
      _currentSizeBytes += imageSize;
      _pendingLotties.remove(key);

      _cache[key] = image;
      _checkCacheSize();

      return composition;
    }

    if (maximumSize > 0 && maximumSizeBytes > 0) {
      _pendingLotties[key] = result.then(listener);
    }
    return result;
  }

  // Remove images from the cache until both the length and bytes are below
  // maximum, or the cache is empty.
  void _checkCacheSize() {
    while (
        _currentSizeBytes > _maximumSizeBytes || _cache.length > _maximumSize) {
      final Object key = _cache.keys.first;
      final _CachedLottie image = _cache[key];
      _currentSizeBytes -= image.sizeBytes;
      _cache.remove(key);
    }
    assert(_currentSizeBytes >= 0);
    assert(_cache.length <= maximumSize);
    assert(_currentSizeBytes <= maximumSizeBytes);
  }
}

class _CachedLottie {
  _CachedLottie(this.composition);

  final LottieComposition composition;
  int get sizeBytes => composition.jsonSize;
}
