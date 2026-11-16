import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../animation/content/content_group.dart';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/text_keyframe_animation.dart';
import '../../animation/keyframe/value_callback_keyframe_animation.dart';
import '../../composition.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../utils.dart';
import '../../utils/characters.dart';
import '../../value/lottie_value_callback.dart';
import '../content/text_range_units.dart';
import '../document_data.dart';
import '../font.dart';
import '../font_character.dart';
import 'base_layer.dart';
import 'layer.dart';

class TextLayer extends BaseLayer {
  // TODO(xha): take from context.
  final TextDirection _textDirection = TextDirection.ltr;
  final _matrix = Matrix4.identity();
  final _fillPaint = Paint()..style = PaintingStyle.fill;
  final _strokePaint = Paint()..style = PaintingStyle.stroke;
  final _contentsForCharacter = <FontCharacter, List<ContentGroup>>{};

  /// If this is paragraph text, one line may wrap depending on the size of the document data box.
  final _textSubLines = <_TextSubLine>[];
  final TextKeyframeAnimation _textAnimation;
  final LottieComposition _composition;

  BaseKeyframeAnimation<Color, Color>? _colorAnimation;

  BaseKeyframeAnimation<Color, Color>? _colorCallbackAnimation;

  BaseKeyframeAnimation<Color, Color>? _strokeColorAnimation;

  BaseKeyframeAnimation<Color, Color>? _strokeColorCallbackAnimation;

  BaseKeyframeAnimation<double, double>? _strokeWidthAnimation;

  BaseKeyframeAnimation<double, double>? _strokeWidthCallbackAnimation;

  BaseKeyframeAnimation<double, double>? _trackingAnimation;

  BaseKeyframeAnimation<double, double>? _trackingCallbackAnimation;

  BaseKeyframeAnimation<double, double>? _textSizeAnimation;

  BaseKeyframeAnimation<double, double>? _textSizeCallbackAnimation;

  BaseKeyframeAnimation<int, int>? _opacityAnimation;

  BaseKeyframeAnimation<int, int>? _textRangeStartAnimation;

  BaseKeyframeAnimation<int, int>? _textRangeEndAnimation;

  BaseKeyframeAnimation<int, int>? _textRangeOffsetAnimation;

  TextRangeUnits _textRangeUnits = TextRangeUnits.charIndex;

  TextLayer(LottieDrawable lottieDrawable, Layer layerModel)
    : _composition = layerModel.composition,
      _textAnimation = layerModel.text!.createAnimation(),
      super(lottieDrawable, layerModel) {
    _textAnimation.addUpdateListener(invalidateSelf);
    addAnimation(_textAnimation);

    var textProperties = layerModel.textProperties;
    var textStyle = textProperties?.textStyle;
    if (textStyle != null && textStyle.color != null) {
      _colorAnimation = textStyle.color!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_colorAnimation);
    }

    if (textStyle != null && textStyle.stroke != null) {
      _strokeColorAnimation = textStyle.stroke!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_strokeColorAnimation);
    }

    if (textStyle != null && textStyle.strokeWidth != null) {
      _strokeWidthAnimation = textStyle.strokeWidth!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_strokeWidthAnimation);
    }

    if (textStyle != null && textStyle.tracking != null) {
      _trackingAnimation = textStyle.tracking!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_trackingAnimation);
    }

    if (textStyle != null && textStyle.opacity != null) {
      _opacityAnimation = textStyle.opacity!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_opacityAnimation);
    }

    var rangeSelector = textProperties?.rangeSelector;
    if (rangeSelector != null && rangeSelector.start != null) {
      _textRangeStartAnimation = rangeSelector.start!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_textRangeStartAnimation);
    }

    if (rangeSelector != null && rangeSelector.end != null) {
      _textRangeEndAnimation = rangeSelector.end!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_textRangeEndAnimation);
    }

    if (rangeSelector != null && rangeSelector.offset != null) {
      _textRangeOffsetAnimation = rangeSelector.offset!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_textRangeOffsetAnimation);
    }

    if (rangeSelector != null) {
      _textRangeUnits = rangeSelector.units;
    }
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    super.getBounds(parentMatrix, applyParents: applyParents);
    // TODO: use the correct text bounds.
    return Rect.fromLTWH(
      0,
      0,
      _composition.bounds.width.toDouble(),
      _composition.bounds.height.toDouble(),
    );
  }

  @override
  void drawLayer(
    Canvas canvas,
    Matrix4 parentMatrix, {
    required int parentAlpha,
  }) {
    var documentData = _textAnimation.value;
    var font = _composition.fonts[documentData.fontName];
    if (font == null) {
      return;
    }
    canvas.save();
    canvas.transform(parentMatrix.storage);

    _configurePaint(documentData, parentAlpha, 0);

    if (lottieDrawable.useTextGlyphs) {
      _drawTextWithGlyphs(
        documentData,
        parentMatrix,
        font,
        canvas,
        parentAlpha,
      );
    } else {
      _drawTextWithFont(documentData, font, canvas, parentAlpha);
    }

    canvas.restore();
  }

  /// Configures the [_fillPaint] and [_strokePaint] used for drawing based on the
  /// currently active text ranges.
  ///
  /// [parentAlpha] is a value from 0 to 255 indicating the alpha of the parented layer.
  void _configurePaint(
    DocumentData documentData,
    int parentAlpha,
    int indexInDocument,
  ) {
    Color fillPaintColor;
    if (_colorCallbackAnimation != null) {
      // dynamic property takes priority
      fillPaintColor = _colorCallbackAnimation!.value;
    } else if (_colorAnimation != null &&
        _isIndexInRangeSelection(indexInDocument)) {
      fillPaintColor = _colorAnimation!.value;
    } else {
      // fall back to the document color
      fillPaintColor = documentData.color;
    }
    _fillPaint.color = fillPaintColor.withValues(alpha: _fillPaint.color.a);

    Color strokePaintColor;
    if (_strokeColorCallbackAnimation != null) {
      strokePaintColor = _strokeColorCallbackAnimation!.value;
    } else if (_strokeColorAnimation != null &&
        _isIndexInRangeSelection(indexInDocument)) {
      strokePaintColor = _strokeColorAnimation!.value;
    } else {
      strokePaintColor = documentData.strokeColor;
    }
    _strokePaint.color = strokePaintColor.withValues(
      alpha: _strokePaint.color.a,
    );

    // These opacity values are in the range 0 to 100.
    var transformOpacity = (transform.opacity?.value ?? 100).clamp(0, 100);
    var textRangeOpacity =
        _opacityAnimation != null && _isIndexInRangeSelection(indexInDocument)
        ? _opacityAnimation!.value.clamp(0, 100)
        : 100;

    // This alpha value needs to be in the range 0 to 255 to be applied to the Paint
    // instances. We map the layer transform's opacity into that range and multiply it by
    // the fractional opacity of the text range and the parent.
    var alpha =
        (transformOpacity *
                255 /
                100 *
                (textRangeOpacity / 100) *
                parentAlpha /
                255)
            .round();
    _fillPaint.setAlpha(alpha);
    _strokePaint.setAlpha(alpha);

    if (_strokeWidthCallbackAnimation != null) {
      _strokePaint.strokeWidth = _strokeWidthCallbackAnimation!.value;
    } else if (_strokeWidthAnimation != null &&
        _isIndexInRangeSelection(indexInDocument)) {
      _strokePaint.strokeWidth = _strokeWidthAnimation!.value;
    } else {
      _strokePaint.strokeWidth = documentData.strokeWidth;
    }
  }

  bool _isIndexInRangeSelection(int indexInDocument) {
    var textLength = _textAnimation.value.text.length;
    var textRangeStartAnimation = _textRangeStartAnimation;
    var textRangeEndAnimation = _textRangeEndAnimation;
    if (textRangeStartAnimation != null && textRangeEndAnimation != null) {
      // After Effects supports reversed text ranges where the start index is greater than
      // the end index. For the purposes of determining if the given index is inside of the
      // range, we take the start as the smaller value.
      var rangeStart = math.min(
        textRangeStartAnimation.value,
        textRangeEndAnimation.value,
      );
      var rangeEnd = math.max(
        textRangeStartAnimation.value,
        textRangeEndAnimation.value,
      );

      var textRangeOffsetAnimation = _textRangeOffsetAnimation;
      if (textRangeOffsetAnimation != null) {
        var offset = textRangeOffsetAnimation.value;
        rangeStart += offset;
        rangeEnd += offset;
      }

      if (_textRangeUnits == TextRangeUnits.charIndex) {
        return indexInDocument >= rangeStart && indexInDocument < rangeEnd;
      } else {
        var currentIndexAsPercent = indexInDocument / textLength * 100;
        return currentIndexAsPercent >= rangeStart &&
            currentIndexAsPercent < rangeEnd;
      }
    }
    return true;
  }

  void _drawTextWithGlyphs(
    DocumentData documentData,
    Matrix4 parentMatrix,
    Font font,
    Canvas canvas,
    int parentAlpha,
  ) {
    double textSize;
    if (_textSizeCallbackAnimation != null) {
      textSize = _textSizeCallbackAnimation!.value;
    } else if (_textSizeAnimation != null) {
      textSize = _textSizeAnimation!.value;
    } else {
      textSize = documentData.size;
    }
    var fontScale = textSize / 100.0;
    var parentScale = parentMatrix.getScale();

    var text = documentData.text;

    // Split full text in multiple lines
    var textLines = _getTextLines(text);
    var textLineCount = textLines.length;
    // Add tracking
    var tracking = documentData.tracking / 10;
    if (_trackingCallbackAnimation != null) {
      tracking += _trackingCallbackAnimation!.value;
    } else if (_trackingAnimation != null) {
      tracking += _trackingAnimation!.value;
    }
    var lineIndex = -1;
    for (var i = 0; i < textLineCount; i++) {
      var textLine = textLines[i];
      var boxWidth = documentData.boxSize?.dx ?? 0.0;
      var lines = _splitGlyphTextIntoLines(
        textLine,
        boxWidth,
        font,
        fontScale,
        tracking,
        null,
      );
      for (var j = 0; j < lines.length; j++) {
        var line = lines[j];
        lineIndex++;

        canvas.save();

        _offsetCanvas(canvas, documentData, lineIndex, line.width);
        _drawGlyphTextLine(
          line.text,
          documentData,
          font,
          canvas,
          parentScale,
          fontScale,
          tracking,
          parentAlpha,
        );

        canvas.restore();
      }
    }
  }

  void _drawGlyphTextLine(
    Characters text,
    DocumentData documentData,
    Font font,
    Canvas canvas,
    double parentScale,
    double fontScale,
    double tracking,
    int parentAlpha,
  ) {
    var index = 0;
    for (var c in text) {
      var characterHash = FontCharacter.hashFor(c, font.family, font.style);
      var character = _composition.characters[characterHash];
      if (character == null) {
        // Something is wrong. Potentially, they didn't export the text as a glyph.
        index++;
        continue;
      }
      _drawCharacterAsGlyph(
        character,
        fontScale,
        documentData,
        canvas,
        index,
        parentAlpha,
      );
      var tx = character.width * fontScale + tracking;
      canvas.translate(tx, 0);
      index++;
    }
  }

  void _drawTextWithFont(
    DocumentData documentData,
    Font font,
    Canvas canvas,
    int parentAlpha,
  ) {
    var textStyle = lottieDrawable.getTextStyle(font.family, font.style);
    var embeddedFamily = font.embeddedFamily;
    if (embeddedFamily != null && textStyle.fontFamily == font.family) {
      // Glyphs missing from the embedded font come from the app's font.
      textStyle = textStyle.copyWith(
        fontFamily: embeddedFamily,
        fontFamilyFallback: [font.family, ...?textStyle.fontFamilyFallback],
      );
    }
    var text = documentData.text;
    var textDelegate = lottieDrawable.delegates?.text;
    if (textDelegate != null) {
      text = textDelegate(text);
    }
    double textSize;
    if (_textSizeCallbackAnimation != null) {
      textSize = _textSizeCallbackAnimation!.value;
    } else if (_textSizeAnimation != null) {
      textSize = _textSizeAnimation!.value;
    } else {
      textSize = documentData.size;
    }
    textStyle = textStyle.copyWith(fontSize: textSize);

    // Calculate tracking
    var tracking = documentData.tracking / 10;
    if (_trackingCallbackAnimation != null) {
      tracking += _trackingCallbackAnimation!.value;
    } else if (_trackingAnimation != null) {
      tracking += _trackingAnimation!.value;
    }
    tracking = tracking * textSize / 100.0;

    var delegates = lottieDrawable.delegates;
    if (delegates?.textDirection != null ||
        delegates?.textStyleForRange != null) {
      _drawTextParagraph(
        documentData,
        text,
        textStyle.copyWith(
          letterSpacing: tracking + (textStyle.letterSpacing ?? 0.0),
        ),
        canvas,
        parentAlpha,
      );
      return;
    }

    // Split full text in multiple lines
    var textLines = _getTextLines(text);
    var textLineCount = textLines.length;
    var lineIndex = -1;
    var characterIndexAtStartOfLine = 0;
    for (var i = 0; i < textLineCount; i++) {
      var textLine = textLines[i];
      var boxWidth = documentData.boxSize?.dx ?? 0.0;
      var lines = _splitGlyphTextIntoLines(
        textLine,
        boxWidth,
        font,
        0.0,
        tracking,
        textStyle,
      );
      for (var j = 0; j < lines.length; j++) {
        var line = lines[j];
        lineIndex++;

        canvas.save();

        _offsetCanvas(canvas, documentData, lineIndex, line.width);
        _drawFontTextLine(
          line.text,
          textStyle,
          documentData,
          canvas,
          tracking,
          characterIndexAtStartOfLine,
          parentAlpha,
        );

        characterIndexAtStartOfLine += line.text.length;

        canvas.restore();
      }
    }
  }

  void _drawTextParagraph(
    DocumentData documentData,
    String text,
    TextStyle textStyle,
    Canvas canvas,
    int parentAlpha,
  ) {
    var fontSize = textStyle.fontSize!;
    if (text.isEmpty || fontSize <= 0.0) return;

    // Lines stay lineHeight apart when the text size is animated, as in the
    // other renderers.
    if (textStyle.height == null && documentData.lineHeight > 0.0) {
      textStyle = textStyle.copyWith(
        height: documentData.lineHeight / fontSize,
      );
    }
    var delegates = lottieDrawable.delegates;

    var graphemes = <_Grapheme>[];
    var index = 0;
    var offset = 0;
    for (var character in text.characters) {
      var end = offset + character.length;
      var style = delegates?.textStyleForRange?.call(text, offset, end);
      offset = end;
      _configurePaint(documentData, parentAlpha, index);
      var opacity = _fillPaint.color.a;
      var color = style?.color;
      var normalized = switch (character) {
        '\r\n' || '\r' || '\u0003' => '\n',
        _ => character,
      };
      if (normalized != '\n') index++;
      graphemes.add((
        text: normalized,
        style: style,
        opacity: opacity,
        fill: color == null
            ? _fillPaint.color
            : color.withValues(alpha: color.a * opacity),
        stroke: _strokePaint.strokeWidth > 0.0
            ? _strokePaint.color
            : const Color(0x00000000),
        strokeWidth: _strokePaint.strokeWidth,
      ));
    }

    var decorated = false;
    for (var stroke
        in documentData.strokeOverFill ? [false, true] : [true, false]) {
      var runs = <_ParagraphRun>[];
      for (var grapheme in graphemes) {
        var color = stroke ? grapheme.stroke : grapheme.fill;
        var width = stroke ? grapheme.strokeWidth : 0.0;
        // Compare colors before Paint quantizes them, keeping ligatures intact.
        if (runs.isEmpty ||
            runs.last.color != color ||
            runs.last.width != width ||
            runs.last.opacity != grapheme.opacity ||
            runs.last.style != grapheme.style) {
          runs.add((
            text: StringBuffer(),
            style: grapheme.style,
            opacity: grapheme.opacity,
            color: color,
            width: width,
          ));
        }
        runs.last.text.write(grapheme.text);
      }
      // Backgrounds and shadows are painted once, under the fill and the stroke.
      var styles = [
        for (var run in runs)
          _paragraphRunStyle(
            textStyle.merge(run.style),
            run,
            stroke: stroke,
            decorate: !decorated,
          ),
      ];
      if (!styles.any(_paintsSomething)) continue;
      decorated = true;

      var painter = TextPainter(
        text: TextSpan(
          style: textStyle,
          children: [
            for (var i = 0; i < runs.length; i++)
              TextSpan(text: runs[i].text.toString(), style: styles[i]),
          ],
        ),
        textDirection: delegates?.textDirection ?? _textDirection,
        textAlign: switch (documentData.justification) {
          Justification.leftAlign => TextAlign.left,
          Justification.rightAlign => TextAlign.right,
          Justification.center => TextAlign.center,
        },
      );
      var boxWidth = documentData.boxSize?.dx ?? 0.0;
      painter.layout(maxWidth: boxWidth > 0.0 ? boxWidth : double.infinity);

      canvas.save();
      _offsetCanvas(canvas, documentData, 0, painter.width);
      var baseline = painter.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );
      painter.paint(
        canvas,
        Offset(0.0, -baseline - documentData.baselineShift),
      );
      canvas.restore();
      painter.dispose();
    }
  }

  TextStyle _paragraphRunStyle(
    TextStyle style,
    _ParagraphRun run, {
    required bool stroke,
    required bool decorate,
  }) {
    Color fade(Color color) => color.withValues(alpha: color.a * run.opacity);
    Paint? background;
    if (style.background != null || style.backgroundColor != null) {
      var paint = style.background ?? (Paint()..color = style.backgroundColor!);
      // The copy keeps the shader and filters of the paint.
      background = decorate
          ? (Paint.from(paint)..color = fade(paint.color))
          : (Paint()..color = const Color(0x00000000));
    }
    var decorationColor = style.decorationColor;
    return style.copyWith(
      foreground: Paint()
        ..color = run.color
        ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = run.width,
      background: background,
      shadows: style.shadows == null
          ? null
          : [
              if (decorate)
                for (var shadow in style.shadows!)
                  Shadow(
                    color: fade(shadow.color),
                    offset: shadow.offset,
                    blurRadius: shadow.blurRadius,
                  ),
            ],
      decoration: stroke ? TextDecoration.none : style.decoration,
      decorationColor: decorationColor == null ? null : fade(decorationColor),
    );
  }

  static bool _paintsSomething(TextStyle style) {
    var decoration = style.decoration ?? TextDecoration.none;
    return style.foreground!.color.a > 0.0 ||
        (style.background?.color.a ?? 0.0) > 0.0 ||
        (style.shadows?.any((shadow) => shadow.color.a > 0.0) ?? false) ||
        (decoration != TextDecoration.none &&
            (style.decorationColor?.a ?? 0.0) > 0.0);
  }

  void _offsetCanvas(
    Canvas canvas,
    DocumentData documentData,
    int lineIndex,
    double lineWidth,
  ) {
    var position = documentData.boxPosition;
    var size = documentData.boxSize;
    var lineStartY = position == null
        ? 0
        : documentData.lineHeight + position.dy;
    var lineOffset = lineIndex * documentData.lineHeight + lineStartY;
    var lineStart = position?.dx ?? 0.0;
    var boxWidth = size?.dx ?? 0.0;
    switch (documentData.justification) {
      case Justification.leftAlign:
        canvas.translate(lineStart, lineOffset);
      case Justification.rightAlign:
        canvas.translate(lineStart + boxWidth - lineWidth, lineOffset);
      case Justification.center:
        canvas.translate(
          lineStart + boxWidth / 2.0 - lineWidth / 2.0,
          lineOffset,
        );
    }
  }

  List<Characters> _getTextLines(String text) {
    // Split full text by carriage return character
    var formattedText = text
        .replaceAll('\r\n', '\r')
        .replaceAll('\u0003', '\r')
        .replaceAll('\n', '\r');
    var textLinesArray = formattedText.split('\r');
    return textLinesArray.map((l) => l.characters).toList();
  }

  /// [characterIndexAtStartOfLine] is the index within the overall document of the character
  /// at the start of the line.
  void _drawFontTextLine(
    Characters text,
    TextStyle textStyle,
    DocumentData documentData,
    Canvas canvas,
    double tracking,
    int characterIndexAtStartOfLine,
    int parentAlpha,
  ) {
    var index = 0;
    for (var char in text) {
      var charString = char;
      _drawCharacterFromFont(
        charString,
        textStyle,
        documentData,
        canvas,
        characterIndexAtStartOfLine + index,
        parentAlpha,
      );
      var textPainter = TextPainter(
        text: TextSpan(text: charString, style: textStyle),
        textDirection: _textDirection,
      );
      textPainter.layout();
      var charWidth = textPainter.width;
      var tx = charWidth + tracking;
      canvas.translate(tx, 0);
      index++;
    }
  }

  List<_TextSubLine> _splitGlyphTextIntoLines(
    Characters textLine,
    double boxWidth,
    Font font,
    double fontScale,
    double tracking,
    TextStyle? textStyle,
  ) {
    var usingGlyphs = textStyle == null;
    var lineCount = 0;

    var currentLineWidth = 0.0;
    var currentLineStartIndex = 0;

    var currentWordStartIndex = 0;
    var currentWordWidth = 0.0;
    var nextCharacterStartsWord = false;

    // The measured size of a space.
    var spaceWidth = 0.0;

    var textPainter = TextPainter(
      text: TextSpan(text: '', style: textStyle),
      textDirection: _textDirection,
    );
    var i = 0;
    for (var c in textLine) {
      double currentCharWidth;
      if (usingGlyphs) {
        var characterHash = FontCharacter.hashFor(c, font.family, font.style);
        var character = _composition.characters[characterHash];
        if (character == null) {
          continue;
        }
        currentCharWidth = character.width * fontScale + tracking;
      } else {
        textPainter.text = TextSpan(text: c, style: textStyle);
        textPainter.layout();
        currentCharWidth = textPainter.width + tracking;
      }

      if (c == ' ') {
        spaceWidth = currentCharWidth;
        nextCharacterStartsWord = true;
      } else if (nextCharacterStartsWord) {
        nextCharacterStartsWord = false;
        currentWordStartIndex = i;
        currentWordWidth = currentCharWidth;
      } else {
        currentWordWidth += currentCharWidth;
      }
      currentLineWidth += currentCharWidth;

      if (boxWidth > 0 && currentLineWidth >= boxWidth) {
        if (c == ' ') {
          // Spaces at the end of a line don't do anything. Ignore it.
          // The next non-space character will hit the conditions below.
          continue;
        }
        var subLine = _ensureEnoughSubLines(++lineCount);
        if (currentWordStartIndex == currentLineStartIndex) {
          // Only word on line is wider than box, start wrapping mid-word.
          var substr = textLine.getRange(currentLineStartIndex, i);
          var trimmed = substr.trim(' '.characters);
          var trimmedSpace = (trimmed.length - substr.length) * spaceWidth;
          subLine.set(
            trimmed,
            currentLineWidth - currentCharWidth - trimmedSpace,
          );
          currentLineStartIndex = i;
          currentLineWidth = currentCharWidth;
          currentWordStartIndex = currentLineStartIndex;
          currentWordWidth = currentCharWidth;
        } else {
          var substr = textLine.getRange(
            currentLineStartIndex,
            currentWordStartIndex - 1,
          );
          var trimmed = substr.trim(' '.characters);
          var trimmedSpace = (substr.length - trimmed.length) * spaceWidth;
          subLine.set(
            trimmed,
            currentLineWidth - currentWordWidth - trimmedSpace - spaceWidth,
          );
          currentLineStartIndex = currentWordStartIndex;
          currentLineWidth = currentWordWidth;
        }
      }
      ++i;
    }
    if (currentLineWidth > 0) {
      var line = _ensureEnoughSubLines(++lineCount);
      line.set(textLine.getRange(currentLineStartIndex), currentLineWidth);
    }
    return _textSubLines.sublist(0, lineCount);
  }

  /// Elements are reused and not deleted to save allocations.
  _TextSubLine _ensureEnoughSubLines(int numLines) {
    for (var i = _textSubLines.length; i < numLines; i++) {
      _textSubLines.add(_TextSubLine());
    }
    return _textSubLines[numLines - 1];
  }

  void _drawCharacterAsGlyph(
    FontCharacter character,
    double fontScale,
    DocumentData documentData,
    Canvas canvas,
    int indexInDocument,
    int parentAlpha,
  ) {
    _configurePaint(documentData, parentAlpha, indexInDocument);
    var contentGroups = _getContentsForCharacter(character);
    for (var j = 0; j < contentGroups.length; j++) {
      var path = contentGroups[j].getPath();
      _matrix.reset();
      _matrix.translateByDouble(0.0, -documentData.baselineShift, 0, 1);
      _matrix.scaleByDouble(fontScale, fontScale, fontScale, 1);
      path = path.transform(_matrix.storage);
      if (documentData.strokeOverFill) {
        _drawGlyph(path, _fillPaint, canvas);
        _drawGlyph(path, _strokePaint, canvas);
      } else {
        _drawGlyph(path, _strokePaint, canvas);
        _drawGlyph(path, _fillPaint, canvas);
      }
    }
  }

  void _drawGlyph(Path path, Paint paint, Canvas canvas) {
    if (paint.color.a == 0) {
      return;
    }
    if (paint.style == PaintingStyle.stroke && paint.strokeWidth == 0) {
      return;
    }
    canvas.drawPath(path, paint);
  }

  void _drawCharacterFromFont(
    String character,
    TextStyle textStyle,
    DocumentData documentData,
    Canvas canvas,
    int indexInDocument,
    int parentAlpha,
  ) {
    _configurePaint(documentData, parentAlpha, indexInDocument);
    if (documentData.strokeOverFill) {
      _drawCharacter(character, textStyle, _fillPaint, canvas);
      _drawCharacter(character, textStyle, _strokePaint, canvas);
    } else {
      _drawCharacter(character, textStyle, _strokePaint, canvas);
      _drawCharacter(character, textStyle, _fillPaint, canvas);
    }
  }

  void _drawCharacter(
    String character,
    TextStyle textStyle,
    Paint paint,
    Canvas canvas,
  ) {
    if (paint.color.a == 0) {
      return;
    }
    if (paint.style == PaintingStyle.stroke && paint.strokeWidth == 0) {
      return;
    }

    textStyle = textStyle.copyWith(foreground: paint);

    var painter = TextPainter(
      text: TextSpan(text: character, style: textStyle),
      textDirection: _textDirection,
    );
    painter.layout();
    painter.paint(canvas, Offset(0, -textStyle.fontSize!));
  }

  List<ContentGroup> _getContentsForCharacter(FontCharacter character) {
    if (_contentsForCharacter.containsKey(character)) {
      return _contentsForCharacter[character]!;
    }
    var shapes = character.shapes;
    var size = shapes.length;
    var contents = <ContentGroup>[];
    for (var i = 0; i < size; i++) {
      var sg = shapes[i];
      contents.add(ContentGroup(lottieDrawable, this, sg));
    }
    _contentsForCharacter[character] = contents;
    return contents;
  }

  @override
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback) {
    super.addValueCallback(property, callback);
    if (property == LottieProperty.color) {
      if (_colorCallbackAnimation != null) {
        removeAnimation(_colorCallbackAnimation);
      }

      if (callback == null) {
        _colorCallbackAnimation = null;
      } else {
        _colorCallbackAnimation = ValueCallbackKeyframeAnimation(
          callback as LottieValueCallback<Color>,
          const Color(0x00000000),
        )..addUpdateListener(invalidateSelf);
        addAnimation(_colorCallbackAnimation);
      }
    } else if (property == LottieProperty.strokeColor) {
      if (_strokeColorCallbackAnimation != null) {
        removeAnimation(_strokeColorCallbackAnimation);
      }

      if (callback == null) {
        _strokeColorCallbackAnimation = null;
      } else {
        _strokeColorCallbackAnimation = ValueCallbackKeyframeAnimation(
          callback as LottieValueCallback<Color>,
          const Color(0x00000000),
        )..addUpdateListener(invalidateSelf);
        addAnimation(_strokeColorCallbackAnimation);
      }
    } else if (property == LottieProperty.strokeWidth) {
      if (_strokeWidthCallbackAnimation != null) {
        removeAnimation(_strokeWidthCallbackAnimation);
      }

      if (callback == null) {
        _strokeWidthCallbackAnimation = null;
      } else {
        _strokeWidthCallbackAnimation = ValueCallbackKeyframeAnimation(
          callback as LottieValueCallback<double>,
          0,
        )..addUpdateListener(invalidateSelf);
        addAnimation(_strokeWidthCallbackAnimation);
      }
    } else if (property == LottieProperty.textTracking) {
      if (_trackingCallbackAnimation != null) {
        removeAnimation(_trackingCallbackAnimation);
      }

      if (callback == null) {
        _trackingCallbackAnimation = null;
      } else {
        _trackingCallbackAnimation = ValueCallbackKeyframeAnimation(
          callback as LottieValueCallback<double>,
          0,
        )..addUpdateListener(invalidateSelf);
        addAnimation(_trackingCallbackAnimation);
      }
    } else if (property == LottieProperty.textSize) {
      if (_textSizeCallbackAnimation != null) {
        removeAnimation(_textSizeCallbackAnimation);
      }

      if (callback == null) {
        _textSizeCallbackAnimation = null;
      } else {
        _textSizeCallbackAnimation = ValueCallbackKeyframeAnimation(
          callback as LottieValueCallback<double>,
          10,
        )..addUpdateListener(invalidateSelf);
        addAnimation(_textSizeCallbackAnimation);
      }
    } else if (property == LottieProperty.text) {
      if (callback != null) {
        _textAnimation.setStringValueCallback(
          callback as LottieValueCallback<String>,
        );
      }
    }
  }
}

typedef _Grapheme = ({
  String text,
  TextStyle? style,
  double opacity,
  Color fill,
  Color stroke,
  double strokeWidth,
});

typedef _ParagraphRun = ({
  StringBuffer text,
  TextStyle? style,
  double opacity,
  Color color,
  double width,
});

class _TextSubLine {
  Characters text = Characters.empty;
  double width = 0.0;

  void set(Characters text, double width) {
    this.text = text;
    this.width = width;
  }
}
