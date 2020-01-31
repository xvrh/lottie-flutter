import 'dart:typed_data';
import '../composition.dart';
import 'lottie_provider.dart';

class MemoryLottie extends LottieProvider {
  MemoryLottie(this.bytes);

  final Uint8List bytes;

  @override
  Future<LottieComposition> load() async {
    // TODO(xha): hash the list content
    var cacheKey = 'memory-${bytes.hashCode}-${bytes.lengthInBytes}';
    return sharedLottieCache.putIfAbsent(cacheKey, () async {
      return LottieComposition.fromBytes(bytes);
    });
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other is MemoryLottie && other.bytes == bytes;
  }

  @override
  int get hashCode => bytes.hashCode;

  @override
  String toString() => '$runtimeType(bytes: ${bytes.length})';
}
