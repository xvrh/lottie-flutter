import 'dart:ui';
import 'package:characters/characters.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../animation/content/content_group.dart';
import '../../animation/keyframe/base_keyframe_animation.dart';
import '../../animation/keyframe/text_keyframe_animation.dart';
import '../../animation/keyframe/value_callback_keyframe_animation.dart';
import '../../composition.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../utils.dart';
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
  final TextKeyframeAnimation _textAnimation;
  final LottieComposition _composition;

  BaseKeyframeAnimation<Color, Color> /*?*/ _colorAnimation;

  BaseKeyframeAnimation<Color, Color> /*?*/ _colorCallbackAnimation;

  BaseKeyframeAnimation<Color, Color> /*?*/ _strokeColorAnimation;

  BaseKeyframeAnimation<Color, Color> /*?*/ _strokeColorCallbackAnimation;

  BaseKeyframeAnimation<double, double> /*?*/ _strokeWidthAnimation;

  BaseKeyframeAnimation<double, double> /*?*/ _strokeWidthCallbackAnimation;

  BaseKeyframeAnimation<double, double> /*?*/ _trackingAnimation;

  BaseKeyframeAnimation<double, double> /*?*/ _trackingCallbackAnimation;

  BaseKeyframeAnimation<double, double> /*?*/ _textSizeAnimation;

  BaseKeyframeAnimation<double, double> /*?*/ _textSizeCallbackAnimation;

  TextLayer(LottieDrawable lottieDrawable, Layer layerModel)
      : _composition = layerModel.composition,
        _textAnimation = layerModel.text.createAnimation(),
        super(lottieDrawable, layerModel) {
    _textAnimation.addUpdateListener(invalidateSelf);
    addAnimation(_textAnimation);

    var textProperties = layerModel.textProperties;
    if (textProperties != null && textProperties.color != null) {
      _colorAnimation = textProperties.color.createAnimation();
      _colorAnimation.addUpdateListener(invalidateSelf);
      addAnimation(_colorAnimation);
    }

    if (textProperties != null && textProperties.stroke != null) {
      _strokeColorAnimation = textProperties.stroke.createAnimation();
      _strokeColorAnimation.addUpdateListener(invalidateSelf);
      addAnimation(_strokeColorAnimation);
    }

    if (textProperties != null && textProperties.strokeWidth != null) {
      _strokeWidthAnimation = textProperties.strokeWidth.createAnimation();
      _strokeWidthAnimation.addUpdateListener(invalidateSelf);
      addAnimation(_strokeWidthAnimation);
    }

    if (textProperties != null && textProperties.tracking != null) {
      _trackingAnimation = textProperties.tracking.createAnimation();
      _trackingAnimation.addUpdateListener(invalidateSelf);
      addAnimation(_trackingAnimation);
    }
  }

  @override
  Rect getBounds(Matrix4 parentMatrix, {bool applyParents}) {
    super.getBounds(parentMatrix, applyParents: applyParents);
    // TODO: use the correct text bounds.
    return Rect.fromLTWH(0, 0, _composition.bounds.width.toDouble(),
        _composition.bounds.height.toDouble());
  }

  @override
  void drawLayer(Canvas canvas, Size size, Matrix4 parentMatrix,
      {int parentAlpha}) {
    canvas.save();
    if (!lottieDrawable.useTextGlyphs) {
      canvas.transform(parentMatrix.storage);
    }
    var documentData = _textAnimation.value;
    var font = _composition.fonts[documentData.fontName];
    if (font == null) {
      // Something is wrong.
      canvas.restore();
      return;
    }

    Color fillPaintColor;
    if (_colorCallbackAnimation != null) {
      fillPaintColor = _colorCallbackAnimation.value;
    } else if (_colorAnimation != null) {
      fillPaintColor = _colorAnimation.value;
    } else {
      fillPaintColor = documentData.color;
    }
    _fillPaint.color = fillPaintColor.withAlpha(_fillPaint.color.alpha);

    Color strokePaintColor;
    if (_strokeColorCallbackAnimation != null) {
      strokePaintColor = _strokeColorCallbackAnimation.value;
    } else if (_strokeColorAnimation != null) {
      strokePaintColor = _strokeColorAnimation.value;
    } else {
      strokePaintColor = documentData.strokeColor;
    }
    _strokePaint.color = strokePaintColor.withAlpha(_strokePaint.color.alpha);

    var opacity = transform.opacity == null ? 100 : transform.opacity.value;
    var alpha = (opacity * 255 / 100).round();
    _fillPaint.setAlpha(alpha);
    _strokePaint.setAlpha(alpha);

    if (_strokeWidthCallbackAnimation != null) {
      _strokePaint.strokeWidth = _strokeWidthCallbackAnimation.value;
    } else if (_strokeWidthAnimation != null) {
      _strokePaint.strokeWidth = _strokeWidthAnimation.value;
    } else {
      var parentScale = parentMatrix.getScale();
      _strokePaint.strokeWidth =
          documentData.strokeWidth * window.devicePixelRatio * parentScale;
    }

    if (lottieDrawable.useTextGlyphs) {
      _drawTextGlyphs(documentData, parentMatrix, font, canvas);
    } else {
      _drawTextWithFont(documentData, font, parentMatrix, canvas);
    }

    canvas.restore();
  }

  void _drawTextGlyphs(DocumentData documentData, Matrix4 parentMatrix,
      Font font, Canvas canvas) {
    double textSize;
    if (_textSizeCallbackAnimation != null) {
      textSize = _textSizeCallbackAnimation.value;
    } else if (_textSizeAnimation != null) {
      textSize = _textSizeAnimation.value;
    } else {
      textSize = documentData.size;
    }
    var fontScale = textSize / 100.0;
    var parentScale = parentMatrix.getScale();

    var text = documentData.text;

    // Line height
    var lineHeight = documentData.lineHeight * window.devicePixelRatio;

    // Split full text in multiple lines
    var textLines = _getTextLines(text);
    var textLineCount = textLines.length;
    for (var l = 0; l < textLineCount; l++) {
      var textLine = textLines[l];
      var textLineWidth =
          _getTextLineWidthForGlyphs(textLine, font, fontScale, parentScale);

      canvas.save();

      // Apply horizontal justification
      _applyJustification(documentData.justification, canvas, textLineWidth);

      // Center text vertically
      var multilineTranslateY = (textLineCount - 1) * lineHeight / 2;
      var translateY = l * lineHeight - multilineTranslateY;
      canvas.translate(0, translateY);

      // Draw each line
      _drawGlyphTextLine(textLine, documentData, parentMatrix, font, canvas,
          parentScale, fontScale);

      // Reset canvas
      canvas.restore();
    }
  }

  void _drawGlyphTextLine(
      String text,
      DocumentData documentData,
      Matrix4 parentMatrix,
      Font font,
      Canvas canvas,
      double parentScale,
      double fontScale) {
    for (var i = 0; i < text.length; i++) {
      var c = text[i];
      var characterHash = FontCharacter.hashFor(c, font.family, font.style);
      var character = _composition.characters[characterHash];
      if (character == null) {
        // Something is wrong. Potentially, they didn't export the text as a glyph.
        continue;
      }
      _drawCharacterAsGlyph(
          character, parentMatrix, fontScale, documentData, canvas);
      var tx =
          character.width * fontScale * window.devicePixelRatio * parentScale;
      // Add tracking
      var tracking = documentData.tracking / 10.0;
      if (_trackingCallbackAnimation != null) {
        tracking += _trackingCallbackAnimation.value;
      } else if (_trackingAnimation != null) {
        tracking += _trackingAnimation.value;
      }
      tx += tracking * parentScale;
      canvas.translate(tx, 0);
    }
  }

  void _drawTextWithFont(DocumentData documentData, Font font,
      Matrix4 parentMatrix, Canvas canvas) {
    var parentScale = parentMatrix.getScale();
    var textStyle = lottieDrawable.getTextStyle(font.family, font.style);
    if (textStyle == null) {
      return;
    }
    var text = documentData.text;
    var textDelegate = lottieDrawable.delegates?.text;
    if (textDelegate != null) {
      text = textDelegate(text);
    }
    double textSize;
    if (_textSizeCallbackAnimation != null) {
      textSize = _textSizeCallbackAnimation.value;
    } else if (_textSizeAnimation != null) {
      textSize = _textSizeAnimation.value;
    } else {
      textSize = documentData.size;
    }
    textStyle =
        textStyle.copyWith(fontSize: textSize * window.devicePixelRatio);

    // Line height
    var lineHeight = documentData.lineHeight * window.devicePixelRatio;

    // Split full text in multiple lines
    var textLines = _getTextLines(text);
    var textLineCount = textLines.length;
    for (var l = 0; l < textLineCount; l++) {
      var textLine = textLines[l];
      var textPainter = TextPainter(
          text: TextSpan(text: textLine, style: textStyle),
          textDirection: _textDirection);
      textPainter.layout();
      var textLineWidth = textPainter.width;

      // Apply horizontal justification
      _applyJustification(documentData.justification, canvas, textLineWidth);

      // Center text vertically
      var multilineTranslateY = (textLineCount - 1) * lineHeight / 2;
      var translateY = l * lineHeight - multilineTranslateY;
      canvas.translate(0, translateY);

      // Draw each line
      _drawFontTextLine(textLine, textStyle, documentData, canvas, parentScale);

      // Reset canvas
      canvas.transform(parentMatrix.storage);
    }
  }

  List<String> _getTextLines(String text) {
    // Split full text by carriage return character
    var formattedText = text.replaceAll('\r\n', '\r').replaceAll('\n', '\r');
    var textLinesArray = formattedText.split('\r');
    return textLinesArray;
  }

  void _drawFontTextLine(String text, TextStyle textStyle,
      DocumentData documentData, Canvas canvas, double parentScale) {
    for (var char in text.characters) {
      var charString = char;
      _drawCharacterFromFont(charString, textStyle, documentData, canvas);
      var textPainter = TextPainter(
          text: TextSpan(text: charString, style: textStyle),
          textDirection: _textDirection);
      textPainter.layout();
      var charWidth = textPainter.width;
      // Add tracking
      var tracking = documentData.tracking / 10.0;
      if (_trackingCallbackAnimation != null) {
        tracking += _trackingCallbackAnimation.value;
      } else if (_trackingAnimation != null) {
        tracking += _trackingAnimation.value;
      }
      var tx = charWidth + tracking * parentScale;
      canvas.translate(tx, 0);
    }
  }

  double _getTextLineWidthForGlyphs(
      String textLine, Font font, double fontScale, double parentScale) {
    var textLineWidth = 0.0;
    for (var i = 0; i < textLine.length; i++) {
      var c = textLine[i];
      var characterHash = FontCharacter.hashFor(c, font.family, font.style);
      var character = _composition.characters[characterHash];
      if (character == null) {
        continue;
      }
      textLineWidth +=
          character.width * fontScale * window.devicePixelRatio * parentScale;
    }
    return textLineWidth;
  }

  void _applyJustification(
      Justification justification, Canvas canvas, double textLineWidth) {
    switch (justification) {
      case Justification.leftAlign:
        // Do nothing. Default is left aligned.
        break;
      case Justification.rightAlign:
        canvas.translate(-textLineWidth, 0);
        break;
      case Justification.center:
        canvas.translate(-textLineWidth / 2, 0);
        break;
    }
  }

  void _drawCharacterAsGlyph(FontCharacter character, Matrix4 parentMatrix,
      double fontScale, DocumentData documentData, Canvas canvas) {
    var contentGroups = _getContentsForCharacter(character);
    for (var j = 0; j < contentGroups.length; j++) {
      var path = contentGroups[j].getPath();
      path.getBounds();
      _matrix.set(parentMatrix);
      _matrix.translate(
          0.0, -documentData.baselineShift * window.devicePixelRatio);
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
    if (paint.color.alpha == 0) {
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
    if (paint.color.alpha == 0) {
      return;
    }
    if (paint.style == PaintingStyle.stroke && paint.strokeWidth == 0) {
      return;
    }

    if (paint.style == PaintingStyle.fill) {
      textStyle = textStyle.copyWith(foreground: paint);
    } else if (paint.style == PaintingStyle.stroke) {
      textStyle = textStyle.copyWith(background: paint);
    }
    var painter = TextPainter(
      text: TextSpan(text: character, style: textStyle),
      textDirection: _textDirection,
    );
    painter.layout();
    painter.paint(canvas, Offset(0, -textStyle.fontSize));
  }

  List<ContentGroup> _getContentsForCharacter(FontCharacter character) {
    if (_contentsForCharacter.containsKey(character)) {
      return _contentsForCharacter[character];
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
  void addValueCallback<T>(T property, LottieValueCallback<T> /*?*/ callback) {
    super.addValueCallback(property, callback);
    if (property == LottieProperty.color) {
      if (_colorCallbackAnimation != null) {
        removeAnimation(_colorCallbackAnimation);
      }

      if (callback == null) {
        _colorCallbackAnimation = null;
      } else {
        _colorCallbackAnimation = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<Color>);
        _colorCallbackAnimation.addUpdateListener(invalidateSelf);
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
            callback as LottieValueCallback<Color>);
        _strokeColorCallbackAnimation.addUpdateListener(invalidateSelf);
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
            callback as LottieValueCallback<double>);
        _strokeWidthCallbackAnimation.addUpdateListener(invalidateSelf);
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
            callback as LottieValueCallback<double>);
        _trackingCallbackAnimation.addUpdateListener(invalidateSelf);
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
            callback as LottieValueCallback<double>);
        _textSizeCallbackAnimation.addUpdateListener(invalidateSelf);
        addAnimation(_textSizeCallbackAnimation);
      }
    }
  }
}
