import 'dart:typed_data';
import '../composition.dart';
import 'lottie_provider.dart';

class MemoryLottie extends LottieProvider {
  MemoryLottie(this.bytes);

  final Uint8List bytes;

  @override
  Future<LottieComposition> load() async {
    throw UnimplementedError();
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
