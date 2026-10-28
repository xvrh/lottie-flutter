import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

final _fontBytes = File(
  'example/assets/fonts/Comic-Neue.ttf',
).readAsBytesSync();

/// A .lottie archive with a text layer in [family], which is unknown to the
/// app by default, embedding Comic Neue under [fontFile].
Uint8List _dotLottie({
  String? fontFile,
  List<int>? fontBytes,
  String family = 'Embedded',
}) {
  var json = File('example/assets/Tests/DynamicText.json')
      .readAsStringSync()
      .replaceAll('"Comic Neue"', '"$family"')
      .replaceAll('"ComicNeue"', '"Embedded-Regular"');
  var archive = Archive()
    ..addFile(ArchiveFile.string('animations/data.json', json));
  if (fontFile != null) {
    archive.addFile(ArchiveFile.bytes(fontFile, fontBytes ?? _fontBytes));
  }
  return ZipEncoder().encodeBytes(archive);
}

Future<LottieComposition> _load(Uint8List bytes) {
  return MemoryLottie(bytes, decoder: LottieComposition.decodeZip).load();
}

double _textWidth(String fontFamily) {
  var painter = TextPainter(
    text: TextSpan(
      text: 'Hello',
      style: TextStyle(fontFamily: fontFamily, fontSize: 20),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

Future<Uint8List> _render(LottieComposition composition) async {
  var drawable = LottieDrawable(composition);
  var recorder = PictureRecorder();
  drawable.draw(Canvas(recorder), Offset.zero & drawable.size);
  var picture = recorder.endRecording();
  var image = await picture.toImage(
    drawable.size.width.round(),
    drawable.size.height.round(),
  );
  var pixels = await image.toByteData();
  image.dispose();
  picture.dispose();
  return pixels!.buffer.asUint8List();
}

void main() {
  test('embedded fonts are not registered under their family', () async {
    var fallbackWidth = _textWidth('Unknown');

    for (var fontFile in [
      'f/Embedded-Regular.ttf',
      'fonts/Embedded.ttf',
      'f/Embedded-Regular.OTF',
    ]) {
      var composition = await _load(_dotLottie(fontFile: fontFile));
      var font = composition.fonts['Embedded-Regular']!;

      expect(font.embeddedFamily, isNotNull, reason: fontFile);
      expect(_textWidth(font.embeddedFamily!), isNot(fallbackWidth));
      expect(_textWidth('Embedded'), fallbackWidth, reason: fontFile);
    }
  });

  test('text layers are drawn with the embedded font', () async {
    var withFont = await _load(_dotLottie(fontFile: 'f/Embedded-Regular.ttf'));
    var withoutFont = await _load(_dotLottie());

    expect(await _render(withFont), isNot(await _render(withoutFont)));
  });

  test('glyphs missing from the embedded font come from the app', () async {
    var emojiOnly = await _load(
      _dotLottie(
        family: 'Comic Neue',
        fontFile: 'f/Embedded-Regular.ttf',
        fontBytes: File(
          'example/assets/fonts/Noto-Emoji.ttf',
        ).readAsBytesSync(),
      ),
    );
    var withoutFont = await _load(_dotLottie(family: 'Comic Neue'));

    expect(emojiOnly.fonts['Embedded-Regular']!.embeddedFamily, isNotNull);
    expect(await _render(emojiOnly), await _render(withoutFont));
  });

  test('a font file shared by animations gets one family', () async {
    var first = await _load(_dotLottie(fontFile: 'f/Embedded-Regular.ttf'));
    var second = await _load(_dotLottie(fontFile: 'fonts/Embedded.ttf'));

    expect(
      second.fonts['Embedded-Regular']!.embeddedFamily,
      first.fonts['Embedded-Regular']!.embeddedFamily,
    );
  });
}
