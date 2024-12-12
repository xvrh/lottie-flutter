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

  TextLayer(LottieDrawable lottieDrawable, Layer layerModel)
      : _composition = layerModel.composition,
        _textAnimation = layerModel.text!.createAnimation(),
        super(lottieDrawable, layerModel) {
    _textAnimation.addUpdateListener(invalidateSelf);
    addAnimation(_textAnimation);

    var textProperties = layerModel.textProperties;
    if (textProperties != null && textProperties.color != null) {
      _colorAnimation = textProperties.color!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_colorAnimation);
    }

    if (textProperties != null && textProperties.stroke != null) {
      _strokeColorAnimation = textProperties.stroke!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_strokeColorAnimation);
    }

    if (textProperties != null && textProperties.strokeWidth != null) {
      _strokeWidthAnimation = textProperties.strokeWidth!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_strokeWidthAnimation);
    }

    if (textProperties != null && textProperties.tracking != null) {
      _trackingAnimation = textProperties.tracking!.createAnimation()
        ..addUpdateListener(invalidateSelf);
      addAnimation(_trackingAnimation);
    }
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {required bool applyParents}) {
    super.getBounds(parentMatrix, applyParents: applyParents);
    // TODO: use the correct text bounds.
    return Rect.fromLTWH(0, 0, _composition.bounds.width.toDouble(),
        _composition.bounds.height.toDouble());
  }

  @override
  void drawLayer(Canvas canvas, Matrix4 parentMatrix,
      {required int parentAlpha}) {
    var documentData = _textAnimation.value;
    var font = _composition.fonts[documentData.fontName];
    if (font == null) {
      return;
    }
    canvas.save();
    canvas.transform(parentMatrix.storage);

    _configurePaint(documentData, parentAlpha);

    if (lottieDrawable.useTextGlyphs) {
      _drawTextWithGlyphs(documentData, parentMatrix, font, canvas);
    } else {
      _drawTextWithFont(documentData, font, canvas);
    }

    canvas.restore();
  }

  void _configurePaint(DocumentData documentData, int parentAlpha) {
    Color fillPaintColor;
    if (_colorCallbackAnimation != null) {
      fillPaintColor = _colorCallbackAnimation!.value;
    } else if (_colorAnimation != null) {
      fillPaintColor = _colorAnimation!.value;
    } else {
      fillPaintColor = documentData.color;
    }
    _fillPaint.color = fillPaintColor.withValues(alpha: _fillPaint.color.a);

    Color strokePaintColor;
    if (_strokeColorCallbackAnimation != null) {
      strokePaintColor = _strokeColorCallbackAnimation!.value;
    } else if (_strokeColorAnimation != null) {
      strokePaintColor = _strokeColorAnimation!.value;
    } else {
      strokePaintColor = documentData.strokeColor;
    }
    _strokePaint.color =
        strokePaintColor.withValues(alpha: _strokePaint.color.a);

    var opacity = transform.opacity?.value ?? 100;
    var alpha = opacity * 255 / 100 * parentAlpha ~/ 255;
    _fillPaint.setAlpha(alpha);
    _strokePaint.setAlpha(alpha);

    if (_strokeWidthCallbackAnimation != null) {
      _strokePaint.strokeWidth = _strokeWidthCallbackAnimation!.value;
    } else if (_strokeWidthAnimation != null) {
      _strokePaint.strokeWidth = _strokeWidthAnimation!.value;
    } else {
      _strokePaint.strokeWidth = documentData.strokeWidth;
    }
  }

  void _drawTextWithGlyphs(DocumentData documentData, Matrix4 parentMatrix,
      Font font, Canvas canvas) {
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
          textLine, boxWidth, font, fontScale, tracking, null);
      for (var j = 0; j < lines.length; j++) {
        var line = lines[j];
        lineIndex++;

        canvas.save();

        _offsetCanvas(canvas, documentData, lineIndex, line.width);
        _drawGlyphTextLine(line.text, documentData, font, canvas, parentScale,
            fontScale, tracking);

        canvas.restore();
      }
    }
  }

  void _drawGlyphTextLine(Characters text, DocumentData documentData, Font font,
      Canvas canvas, double parentScale, double fontScale, double tracking) {
    for (var c in text) {
      var characterHash = FontCharacter.hashFor(c, font.family, font.style);
      var character = _composition.characters[characterHash];
      if (character == null) {
        // Something is wrong. Potentially, they didn't export the text as a glyph.
        continue;
      }
      _drawCharacterAsGlyph(character, fontScale, documentData, canvas);
      var tx = character.width * fontScale + tracking;
      canvas.translate(tx, 0);
    }
  }

  void _drawTextWithFont(DocumentData documentData, Font font, Canvas canvas) {
    var textStyle = lottieDrawable.getTextStyle(font.family, font.style);
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

    // Split full text in multiple lines
    var textLines = _getTextLines(text);
    var textLineCount = textLines.length;
    var lineIndex = -1;
    for (var i = 0; i < textLineCount; i++) {
      var textLine = textLines[i];
      var boxWidth = documentData.boxSize?.dx ?? 0.0;
      var lines = _splitGlyphTextIntoLines(
          textLine, boxWidth, font, 0.0, tracking, textStyle);
      for (var j = 0; j < lines.length; j++) {
        var line = lines[j];
        lineIndex++;

        canvas.save();

        _offsetCanvas(canvas, documentData, lineIndex, line.width);
        _drawFontTextLine(line.text, textStyle, documentData, canvas, tracking);

        canvas.restore();
      }
    }
  }

  void _offsetCanvas(Canvas canvas, DocumentData documentData, int lineIndex,
      double lineWidth) {
    var position = documentData.boxPosition;
    var size = documentData.boxSize;
    var lineStartY =
        position == null ? 0 : documentData.lineHeight + position.dy;
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
            lineStart + boxWidth / 2.0 - lineWidth / 2.0, lineOffset);
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

  void _drawFontTextLine(Characters text, TextStyle textStyle,
      DocumentData documentData, Canvas canvas, double tracking) {
    for (var char in text) {
      var charString = char;
      _drawCharacterFromFont(charString, textStyle, documentData, canvas);
      var textPainter = TextPainter(
          text: TextSpan(text: charString, style: textStyle),
          textDirection: _textDirection);
      textPainter.layout();
      var charWidth = textPainter.width;
      var tx = charWidth + tracking;
      canvas.translate(tx, 0);
    }
  }

  List<_TextSubLine> _splitGlyphTextIntoLines(
      Characters textLine,
      double boxWidth,
      Font font,
      double fontScale,
      double tracking,
      TextStyle? textStyle) {
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
        textDirection: _textDirection);
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
              trimmed, currentLineWidth - currentCharWidth - trimmedSpace);
          currentLineStartIndex = i;
          currentLineWidth = currentCharWidth;
          currentWordStartIndex = currentLineStartIndex;
          currentWordWidth = currentCharWidth;
        } else {
          var substr = textLine.getRange(
              currentLineStartIndex, currentWordStartIndex - 1);
          var trimmed = substr.trim(' '.characters);
          var trimmedSpace = (substr.length - trimmed.length) * spaceWidth;
          subLine.set(trimmed,
              currentLineWidth - currentWordWidth - trimmedSpace - spaceWidth);
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

  void _drawCharacterAsGlyph(FontCharacter character, double fontScale,
      DocumentData documentData, Canvas canvas) {
    var contentGroups = _getContentsForCharacter(character);
    for (var j = 0; j < contentGroups.length; j++) {
      var path = contentGroups[j].getPath();
      _matrix.reset();
      _matrix.translate(0.0, -documentData.baselineShift);
      _matrix.scale(fontScale, fontScale);
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

  void _drawCharacterFromFont(String character, TextStyle textStyle,
      DocumentData documentData, Canvas canvas) {
    if (documentData.strokeOverFill) {
      _drawCharacter(character, textStyle, _fillPaint, canvas);
      _drawCharacter(character, textStyle, _strokePaint, canvas);
    } else {
      _drawCharacter(character, textStyle, _strokePaint, canvas);
      _drawCharacter(character, textStyle, _fillPaint, canvas);
    }
  }

  void _drawCharacter(
      String character, TextStyle textStyle, Paint paint, Canvas canvas) {
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
            callback as LottieValueCallback<Color>, const Color(0x00000000))
          ..addUpdateListener(invalidateSelf);
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
            callback as LottieValueCallback<Color>, const Color(0x00000000))
          ..addUpdateListener(invalidateSelf);
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
            callback as LottieValueCallback<double>, 0)
          ..addUpdateListener(invalidateSelf);
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
            callback as LottieValueCallback<double>, 0)
          ..addUpdateListener(invalidateSelf);
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
            callback as LottieValueCallback<double>, 10)
          ..addUpdateListener(invalidateSelf);
        addAnimation(_textSizeCallbackAnimation);
      }
    } else if (property == LottieProperty.text) {
      if (callback != null) {
        _textAnimation
            .setStringValueCallback(callback as LottieValueCallback<String>);
      }
    }
  }
}

class _TextSubLine {
  Characters text = Characters.empty;
  double width = 0.0;

  void set(Characters text, double width) {
    this.text = text;
    this.width = width;
  }
}
