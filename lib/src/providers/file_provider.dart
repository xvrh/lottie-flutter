import 'dart:io';
import '../composition.dart';
import 'lottie_provider.dart';

class FileLottie extends LottieProvider {
  FileLottie(this.file);

  final File file;

  @override
  Future<LottieComposition> load() async {
    var cacheKey = 'file-${file.path}';
    return sharedLottieCache.putIfAbsent(cacheKey, () async {
      var bytes = await file.readAsBytes();
      var composition = LottieComposition.fromBytes(bytes);

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
    return other is FileLottie && other.file == file;
  }

  @override
  int get hashCode => file.hashCode;

  @override
  String toString() => '$runtimeType(file: ${file.path})';
}
