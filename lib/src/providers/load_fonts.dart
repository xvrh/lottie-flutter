import 'dart:ui';

import '../composition.dart';

final _loadedFonts = <String, Future<void>>{};

Future<void> ensureLoadedFonts(LottieComposition composition) async {
  var fonts = FontToLoad.getAndClear(composition);
  if (fonts != null) {
    for (var font in fonts) {
      // Fonts registered with loadFontFromList apply to the whole app, so they
      // get a family name derived from their content instead of their own.
      var bytes = font.bytes;
      var family = 'lottie-font-${Object.hashAll(bytes)}-${bytes.length}';
      await (_loadedFonts[family] ??= loadFontFromList(
        bytes,
        fontFamily: family,
      ));
      font.font.embeddedFamily = family;
    }
  }
}
