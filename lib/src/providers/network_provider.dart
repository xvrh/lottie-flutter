import '../composition.dart';
import 'lottie_provider.dart';

class NetworkLottie extends LottieProvider {
  NetworkLottie(this.url);

  final String url;

  @override
  Future<LottieComposition> load() async {
    throw UnimplementedError();
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
