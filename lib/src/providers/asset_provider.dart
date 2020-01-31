import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../composition.dart';
import 'lottie_provider.dart';

class AssetLottie extends LottieProvider {
  AssetLottie(
    this.assetName, {
    this.bundle,
    this.package,
  }) : assert(assetName != null);

  final String assetName;
  String get keyName =>
      package == null ? assetName : 'packages/$package/$assetName';

  final AssetBundle bundle;

  final String package;

  @override
  Future<LottieComposition> load() async {
    var cacheKey = 'asset-$keyName-$bundle';
    return sharedLottieCache.putIfAbsent(cacheKey, () async {
      final chosenBundle = bundle ?? rootBundle;

      var data = await chosenBundle.load(keyName);

      // TODO(xha): try to run it in a `compute` method to not freeze the UI thread.
      var composition = LottieComposition.fromByteData(data);

      // TODO(xha): fetch images and store them in the composition directly
      //    var imageStream = AssetImage().resolve(ImageConfiguration.empty);
      //    ImageStreamListener listener;
      //    listener = ImageStreamListener((image, synchronousLoaded) {
      //      imageStream.removeListener(listener);
      //    }, onError: (_, __) {
      //      // TODO(xha): emit a warning in the file but complete the completer.
      //
      //      imageStream.removeListener(listener);
      //    });
      //    imageStream.addListener(listener);

      return composition;
    });
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AssetLottie &&
        other.keyName == keyName &&
        other.bundle == bundle;
  }

  @override
  int get hashCode => hashValues(keyName, bundle);

  @override
  String toString() => '$runtimeType(bundle: $bundle, name: "$keyName")';
}
