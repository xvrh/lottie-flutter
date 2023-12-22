import 'dart:ui';
import '../composition.dart';

Future<void> ensureLoadedFonts(LottieComposition composition) async {
  var fonts = FontToLoad.getAndClear(composition);
  if (fonts != null) {
    for (var font in fonts) {
      await loadFontFromList(font.bytes, fontFamily: font.family);
    }
  }
}
