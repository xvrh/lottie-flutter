import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

const _persian = 'سلام دنیا، این یک متن فارسی است';

LottieComposition _load(String name, {String Function(String)? patch}) {
  var json = File('example/assets/Tests/$name.json').readAsStringSync();
  if (patch != null) json = patch(json);
  return LottieComposition.parseJsonBytes(utf8.encode(json));
}

TextStyle _arabicFont(LottieFontStyle font) =>
    const TextStyle(fontFamily: 'Noto Naskh Arabic');

TextStyle _roboto(LottieFontStyle font) =>
    const TextStyle(fontFamily: 'Roboto');

String _persianText(String text) => _persian;

void main() {
  void testPanels(
    String description,
    List<(String, LottieComposition, LottieDelegates?, double)> panels,
  ) {
    var name = description
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), '')
        .replaceAll(' ', '_');
    testWidgets(description, (tester) async {
      var bounds = panels.first.$2.bounds;
      var size = Size(
        _cell * panels.length,
        _label + _cell * bounds.height / bounds.width,
      );
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = size * 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_Panels(panels));
      await expectLater(
        find.byType(_Panels),
        matchesGoldenFile('goldens/paragraph_text/$name.png'),
      );
    });
  }

  const paragraph = LottieDelegates(textDirection: TextDirection.ltr);

  for (var asset in ['Multiline', 'BoxPosition', 'Text']) {
    var composition = _load(asset);
    testPanels('$asset glyphs and paragraph', [
      ('glyphs', composition, null, 0.5),
      ('paragraph', composition, paragraph, 0.5),
    ]);
  }

  var multiline = _load('Multiline');
  testPanels('Text size keeps the line height', [
    (
      'glyphs',
      multiline,
      LottieDelegates(
        values: [
          ValueDelegate.textSize(['**'], value: 30),
        ],
      ),
      0.5,
    ),
    (
      'paragraph',
      multiline,
      LottieDelegates(
        textDirection: TextDirection.ltr,
        values: [
          ValueDelegate.textSize(['**'], value: 30),
        ],
      ),
      0.5,
    ),
  ]);

  var baseline = _load('TextBaseline');
  testPanels('Baseline shift', [
    ('glyphs', baseline, null, 0.0),
    (
      'paragraph',
      baseline,
      const LottieDelegates(
        textStyle: _roboto,
        textDirection: TextDirection.ltr,
      ),
      0.0,
    ),
  ]);

  testPanels('Right to left paragraph', [
    for (var (label, justification) in [
      ('left', 0),
      ('right', 1),
      ('center', 2),
    ])
      (
        label,
        _load(
          'TextWithPsLeft',
          patch: (json) => json.replaceAll('"j": 0', '"j": $justification'),
        ),
        const LottieDelegates(
          text: _persianText,
          textStyle: _arabicFont,
          textDirection: TextDirection.rtl,
        ),
        0.0,
      ),
  ]);

  var box = _load('TextWithPsLeft');
  testPanels('Range styles', [
    (
      'word color',
      box,
      LottieDelegates(
        text: _persianText,
        textStyle: _arabicFont,
        textDirection: TextDirection.rtl,
        textStyleForRange: (text, start, end) => start >= 5 && end <= 9
            ? const TextStyle(color: Color(0xFFE53935))
            : null,
      ),
      0.0,
    ),
    (
      'mid-word color',
      box,
      LottieDelegates(
        text: _persianText,
        textStyle: _arabicFont,
        textDirection: TextDirection.rtl,
        textStyleForRange: (text, start, end) =>
            start == 2 ? const TextStyle(color: Color(0xFFE53935)) : null,
      ),
      0.0,
    ),
    (
      'underline, background',
      box,
      LottieDelegates(
        text: _persianText,
        textStyle: _arabicFont,
        textDirection: TextDirection.rtl,
        textStyleForRange: (text, start, end) => start >= 11 && end <= 14
            ? const TextStyle(
                decoration: TextDecoration.underline,
                backgroundColor: Color(0xFFFFEB3B),
              )
            : null,
      ),
      0.0,
    ),
  ]);

  var rangeSelector = _load('text_range_test');
  String arabic(String text) => 'مرحبا بالعالم';
  testPanels('Range selector inside a connected word', [
    for (var progress in [0.5, 0.58])
      (
        '$progress',
        rangeSelector,
        LottieDelegates(
          text: arabic,
          textStyle: _arabicFont,
          textDirection: TextDirection.rtl,
        ),
        progress,
      ),
  ]);

  TextStyle? highlight(String text, int start, int end) => start == 1
      ? const TextStyle(
          backgroundColor: Color(0xFFFFEB3B),
          shadows: [Shadow(color: Color(0x99000000), offset: Offset(6, 6))],
        )
      : null;
  var strokeOverFill = _load('Text');
  var strokeUnderFill = _load(
    'Text',
    patch: (json) => json.replaceAll('"of":true', '"of":false'),
  );
  testPanels('Background and shadow under the stroke', [
    (
      'stroke over fill',
      strokeOverFill,
      LottieDelegates(textStyleForRange: highlight),
      0.0,
    ),
    (
      'stroke under fill',
      strokeUnderFill,
      LottieDelegates(textStyleForRange: highlight),
      0.0,
    ),
    (
      'layer opacity 30%',
      strokeUnderFill,
      LottieDelegates(
        textStyleForRange: highlight,
        values: [
          ValueDelegate.transformOpacity(['**'], value: 30),
        ],
      ),
      0.0,
    ),
  ]);

  test('Range offsets are UTF-16 and keep the line endings', () {
    var ranges = <(String, int, int)>[];
    var drawable = LottieDrawable(_load('Text'))
      ..delegates = LottieDelegates(
        text: (text) => 'a😀\r\nb',
        textStyleForRange: (text, start, end) {
          ranges.add((text.substring(start, end), start, end));
          return null;
        },
      )
      ..setProgress(0);
    var recorder = ui.PictureRecorder();
    drawable.draw(ui.Canvas(recorder), const Rect.fromLTWH(0, 0, 300, 300));
    recorder.endRecording().dispose();

    expect(ranges, [('a', 0, 1), ('😀', 1, 3), ('\r\n', 3, 5), ('b', 5, 6)]);
  });

  test('Paragraph options switch glyphs to the font', () {
    var composition = _load('Text');
    expect(LottieDrawable(composition).useTextGlyphs, isTrue);
    expect(
      LottieDrawable(composition, delegates: paragraph).useTextGlyphs,
      isFalse,
    );
    expect(
      LottieDrawable(
        composition,
        delegates: LottieDelegates(
          textStyleForRange: (text, start, end) => null,
        ),
      ).useTextGlyphs,
      isFalse,
    );
  });

  test('Delegates compare the paragraph options', () {
    TextStyle? style(String text, int start, int end) => null;
    expect(
      const LottieDelegates(textDirection: TextDirection.rtl),
      const LottieDelegates(textDirection: TextDirection.rtl),
    );
    expect(
      const LottieDelegates(textDirection: TextDirection.rtl),
      isNot(const LottieDelegates(textDirection: TextDirection.ltr)),
    );
    expect(
      LottieDelegates(textStyleForRange: style).hashCode,
      LottieDelegates(textStyleForRange: style).hashCode,
    );
    expect(
      LottieDelegates(textStyleForRange: style),
      isNot(LottieDelegates(textStyleForRange: (text, start, end) => null)),
    );
  });
}

class _Panels extends StatelessWidget {
  final List<(String, LottieComposition, LottieDelegates?, double)> panels;

  const _Panels(this.panels);

  @override
  Widget build(BuildContext context) {
    var composition = panels.first.$2;
    var aspect = composition.bounds.height / composition.bounds.width;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: CustomPaint(
          size: Size(_cell * panels.length, _label + _cell * aspect),
          painter: _PanelsPainter(panels),
        ),
      ),
    );
  }
}

const _cell = 260.0;
const _label = 20.0;

class _PanelsPainter extends CustomPainter {
  final List<(String, LottieComposition, LottieDelegates?, double)> panels;

  _PanelsPainter(this.panels);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    for (var i = 0; i < panels.length; i++) {
      var (label, composition, delegates, progress) = panels[i];
      var rect = Rect.fromLTWH(i * _cell, _label, _cell, size.height - _label);
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFDDDDDD),
      );
      LottieDrawable(
          composition,
          delegates: delegates,
          frameRate: FrameRate.max,
        )
        ..setProgress(progress)
        ..draw(canvas, rect);
      TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, Offset(i * _cell + 4, 3));
    }
  }

  @override
  bool shouldRepaint(_PanelsPainter oldDelegate) => true;
}
