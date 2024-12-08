import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../composition.dart';
import 'lottie_provider.dart';

@immutable
class FileLottie extends LottieProvider {
  FileLottie(
    this.file, {
    super.imageProviderFactory,
    super.decoder,
    super.backgroundLoading,
  }) : assert(
          !kIsWeb,
          'Lottie.file is not supported on Flutter Web. '
          'Consider using either Lottie.asset or Lottie.network instead.',
        );

  final Object file;

  @override
  Future<LottieComposition> load({BuildContext? context}) {
    throw UnimplementedError(
        'FileLottie provider is not supported on Web platform');
  }
}
