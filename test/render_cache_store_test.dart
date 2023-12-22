import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:lottie/src/render_cache/key.dart';
import 'package:lottie/src/render_cache/store_raster.dart';

void main() {
  var animationBytes =
      File('example/assets/AndroidWave.json').readAsBytesSync();
  var key1 = CacheKey(
      composition: LottieComposition.parseJsonBytes(animationBytes),
      size: const Size(10, 10),
      config: const [FrameRate.composition],
      delegates: 0);
  var key2 = CacheKey(
      composition: LottieComposition.parseJsonBytes(animationBytes),
      size: const Size(20, 10),
      config: const [FrameRate.composition],
      delegates: 0);

  test('RenderCache acquire/release logic', () async {
    var cache = RasterStore(5000000);

    var user = Object();

    var handle = cache.acquire(user);
    var entry = handle.withKey(key1);
    entry.imageForProgress(0, (p0) {});
    expect(cache.imageCount, 1);

    cache.release(user);
    expect(cache.imageCount, 0);
  });

  test('RenderCache change key', () async {
    var cache = RasterStore(500000);

    var user = Object();

    var handle = cache.acquire(user);
    var entry = handle.withKey(key1);
    entry.imageForProgress(0, (p0) {});
    expect(cache.imageCount, 1);

    entry = handle.withKey(key2);
    expect(cache.imageCount, 0);

    entry.imageForProgress(0, (p0) {});
    entry.imageForProgress(0, (p0) {});
    expect(cache.imageCount, 1);
  });

  test('RenderCache acquire with same key', () async {
    var cache = RasterStore(5000000);

    var user1 = Object();
    var user2 = Object();

    var handle1 = cache.acquire(user1);
    var entry1 = handle1.withKey(key1);
    entry1.imageForProgress(0, (p0) {});
    expect(cache.imageCount, 1);

    var handle2 = cache.acquire(user2);
    var entry2 = handle2.withKey(key1);
    expect(entry1, entry2);

    cache.release(user2);
    expect(cache.imageCount, 1);

    entry1.imageForProgress(1, (p0) {});
    expect(cache.imageCount, 2);
  });

  test('RenderCache change key and release', () async {
    var cache = RasterStore(50000000);

    var user1 = Object();
    var user2 = Object();

    var handle1 = cache.acquire(user1);
    var entry1 = handle1.withKey(key1);
    entry1.imageForProgress(0, (p0) {});
    expect(cache.imageCount, 1);

    var handle2 = cache.acquire(user2);
    var entry2 = handle2.withKey(key1);
    expect(entry1, entry2);

    entry2 = handle2.withKey(key2);
    expect(entry1, isNot(equals(entry2)));
    expect(cache.imageCount, 1);

    entry2.imageForProgress(0, (p0) {});
    expect(cache.imageCount, 2);

    cache.release(user2);
    expect(cache.imageCount, 1);

    cache.release(user1);
    expect(cache.imageCount, 0);
  });
}
