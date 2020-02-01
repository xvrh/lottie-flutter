
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:lottie/src/animation/keyframe/base_keyframe_animation.dart';
import 'package:lottie/src/animation/keyframe/text_keyframe_animation.dart';
import 'package:lottie/src/model/animatable/animatable_text_properties.dart';
import 'package:lottie/src/model/font_character.dart';
import 'package:lottie/src/model/layer/layer.dart';
import 'package:lottie/src/utils/utils.dart';
import 'package:lottie/src/value/lottie_value_callback.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../composition.dart';
import '../../lottie_drawable.dart';
import '../../lottie_property.dart';
import '../../text_delegate.dart';
import '../document_data.dart';
import '../font.dart';
import 'base_layer.dart';
import '../../utils.dart';

class TextLayer extends BaseLayer {
  // Capacity is 2 because emojis are 2 characters. Some are longer in which case, the capacity will
  // be expanded but that should be pretty rare.
  final _stringBuilder =  StringBuffer(2);
  final _matrix =  Matrix4();
  final _fillPaint =  TextPainter()..style = PaintingStyle.fill;
 final _strokePaint =  TextPainter()..style = PaintingStyle.stroke;
final _contentsForCharacter = <FontCharacter, List<ContentGroup>>{};
final  _codePointCache = <int, String>{};
final TextKeyframeAnimation _textAnimation;
final LottieComposition _composition;

 BaseKeyframeAnimation<Color, Color>/*?*/ _colorAnimation;

 BaseKeyframeAnimation<Color, Color>/*?*/ _colorCallbackAnimation;

 BaseKeyframeAnimation<Color, Color>/*?*/ _strokeColorAnimation;

 BaseKeyframeAnimation<Color, Color>/*?*/ _strokeColorCallbackAnimation;

 BaseKeyframeAnimation<double, double>/*?*/ _strokeWidthAnimation;

 BaseKeyframeAnimation<double, double>/*?*/ _strokeWidthCallbackAnimation;

 BaseKeyframeAnimation<double, double>/*?*/ _trackingAnimation;

 BaseKeyframeAnimation<double, double>/*?*/ _trackingCallbackAnimation;

 BaseKeyframeAnimation<double, double>/*?*/ _textSizeAnimation;

 BaseKeyframeAnimation<double, double>/*?*/ _textSizeCallbackAnimation;

TextLayer(LottieDrawable lottieDrawable, Layer layerModel): _composition = layerModel.composition,
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
 Rect getBounds( Matrix4 parentMatrix, {bool applyParents}) {
  super.getBounds(parentMatrix, applyParents: applyParents);
  // TODO: use the correct text bounds.
  return Rect(0, 0, _composition.bounds.width, _composition.bounds.height);
}

@override
void drawLayer(Canvas canvas, Matrix4 parentMatrix, {int parentAlpha}) {
  canvas.save();
  if (!lottieDrawable.useTextGlyphs) {
    canvas.transform(parentMatrix.storage);
  }
  DocumentData documentData = _textAnimation.value;
  Font font = _composition.fonts[documentData.fontName];
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

  int opacity = transform.opacity == null ? 100 : transform.opacity.value;
  var alpha = (opacity * 255 / 100).round();
  _fillPaint.setAlpha(alpha);
  _strokePaint.setAlpha(alpha);

  if (_strokeWidthCallbackAnimation != null) {
    _strokePaint.strokeWidth = _strokeWidthCallbackAnimation.value;
  } else if (_strokeWidthAnimation != null) {
    _strokePaint.strokeWidth = _strokeWidthAnimation.value;
  } else {
    var parentScale = parentMatrix.getScale();
    _strokePaint.strokeWidth = documentData.strokeWidth * window.devicePixelRatio * parentScale;
  }

  if (lottieDrawable.useTextGlyphs) {
    _drawTextGlyphs(documentData, parentMatrix, font, canvas);
  } else {
    _drawTextWithFont(documentData, font, parentMatrix, canvas);
  }

  canvas.restore();
}

 void _drawTextGlyphs(
    DocumentData documentData, Matrix4 parentMatrix, Font font, Canvas canvas) {
  double textSize;
  if (_textSizeCallbackAnimation != null) {
    textSize = _textSizeCallbackAnimation.value;
  } else if (_textSizeAnimation != null) {
    textSize = _textSizeAnimation.value;
  } else {
    textSize = documentData.size;
  }
  double fontScale = textSize / 100.0;
  double parentScale = parentMatrix.getScale();

  String text = documentData.text;

  // Line height
  double lineHeight = documentData.lineHeight * window.devicePixelRatio;

  // Split full text in multiple lines
  List<String> textLines = getTextLines(text);
  int textLineCount = textLines.length;
  for (int l = 0; l < textLineCount; l++) {

    String textLine = textLines.get(l);
    double textLineWidth = _getTextLineWidthForGlyphs(textLine, font, fontScale, parentScale);

    canvas.save();

    // Apply horizontal justification
    applyJustification(documentData.justification, canvas, textLineWidth);

    // Center text vertically
    double multilineTranslateY = (textLineCount - 1) * lineHeight / 2;
    double translateY = l * lineHeight - multilineTranslateY;
    canvas.translate(0, translateY);

    // Draw each line
    drawGlyphTextLine(textLine, documentData, parentMatrix, font, canvas, parentScale, fontScale);

    // Reset canvas
    canvas.restore();
  }
}

 void _drawGlyphTextLine(String text, DocumentData documentData, Matrix4 parentMatrix,
    Font font, Canvas canvas, double parentScale, double fontScale) {
  for (int i = 0; i < text.length; i++) {
    String c = text.charAt(i);
    int characterHash = FontCharacter.hashFor(c, font.family, font.style);
    FontCharacter character = _composition.characters[characterHash];
    if (character == null) {
      // Something is wrong. Potentially, they didn't export the text as a glyph.
      continue;
    }
    drawCharacterAsGlyph(character, parentMatrix, fontScale, documentData, canvas);
    double tx = character.width * fontScale * window.devicePixelRatio * parentScale;
    // Add tracking
    double tracking = documentData.tracking / 10.0;
    if (_trackingCallbackAnimation != null) {
      tracking += _trackingCallbackAnimation.value;
    } else if (_trackingAnimation != null) {
      tracking += _trackingAnimation.value;
    }
    tx += tracking * parentScale;
    canvas.translate(tx, 0);
  }
}

 void _drawTextWithFont(
    DocumentData documentData, Font font, Matrix4 parentMatrix, Canvas canvas) {
  double parentScale = parentMatrix.getScale();
  Typeface typeface = lottieDrawable.getTypeface(font.family, font.style);
  if (typeface == null) {
    return;
  }
  String text = documentData.text;
  TextDelegate textDelegate = lottieDrawable.textDelegate;
  if (textDelegate != null) {
    text = textDelegate.getTextInternal(text);
  }
  _fillPaint.setTypeface(typeface);
  double textSize;
  if (_textSizeCallbackAnimation != null) {
    textSize = _textSizeCallbackAnimation.value;
  } else if (_textSizeAnimation != null) {
    textSize = _textSizeAnimation.value;
  } else {
    textSize = documentData.size;
  }
  _fillPaint.setTextSize(textSize * window.devicePixelRatio);
  _strokePaint.setTypeface(_fillPaint.getTypeface());
  _strokePaint.setTextSize(_fillPaint.getTextSize());

  // Line height
  double lineHeight = documentData.lineHeight * window.devicePixelRatio;

  // Split full text in multiple lines
  List<String> textLines = getTextLines(text);
  int textLineCount = textLines.length;
  for (int l = 0; l < textLineCount; l++) {

    String textLine = textLines.get(l);
    double textLineWidth = _strokePaint.measureText(textLine);

    // Apply horizontal justification
    applyJustification(documentData.justification, canvas, textLineWidth);

    // Center text vertically
    double multilineTranslateY = (textLineCount - 1) * lineHeight / 2;
    double translateY = l * lineHeight - multilineTranslateY;
    canvas.translate(0, translateY);

    // Draw each line
    drawFontTextLine(textLine, documentData, canvas, parentScale);

    // Reset canvas
    canvas.transform(parentMatrix.storage);
  }
}

 List<String> _getTextLines(String text) {
  // Split full text by carriage return character
  String formattedText = text.replaceAll("\r\n", "\r")
      .replaceAll("\n", "\r");
  List<String> textLinesArray = formattedText.split("\r");
  return textLinesArray;
}

 void _drawFontTextLine(String text, DocumentData documentData, Canvas canvas, float parentScale) {
  for (int i = 0; i < text.length(); ) {
    String charString = codePointToString(text, i);
    i += charString.length();
    drawCharacterFromFont(charString, documentData, canvas);
    float charWidth = fillPaint.measureText(charString, 0, 1);
    // Add tracking
    float tracking = documentData.tracking / 10f;
    if (trackingCallbackAnimation != null) {
      tracking += trackingCallbackAnimation.getValue();
    } else if (trackingAnimation != null) {
      tracking += trackingAnimation.getValue();
    }
    float tx = charWidth + tracking * parentScale;
    canvas.translate(tx, 0);
  }
}

 double _getTextLineWidthForGlyphs(
    String textLine, Font font, double fontScale, double parentScale) {
  float textLineWidth = 0;
  for (int i = 0; i < textLine.length(); i++) {
    char c = textLine.charAt(i);
    int characterHash = FontCharacter.hashFor(c, font.getFamily(), font.getStyle());
    FontCharacter character = composition.getCharacters().get(characterHash);
    if (character == null) {
      continue;
    }
    textLineWidth += character.getWidth() * fontScale * Utils.dpScale() * parentScale;
  }
  return textLineWidth;
}

 void _applyJustification(Justification justification, Canvas canvas, float textLineWidth) {
  switch (justification) {
    case LEFT_ALIGN:
    // Do nothing. Default is left aligned.
      break;
    case RIGHT_ALIGN:
      canvas.translate(-textLineWidth, 0);
      break;
    case CENTER:
      canvas.translate(-textLineWidth / 2, 0);
      break;
  }
}

 void _drawCharacterAsGlyph(
    FontCharacter character,
    Matrix parentMatrix,
    float fontScale,
    DocumentData documentData,
    Canvas canvas) {
  List<ContentGroup> contentGroups = getContentsForCharacter(character);
  for (int j = 0; j < contentGroups.size(); j++) {
    Path path = contentGroups.get(j).getPath();
    path.computeBounds(rectF, false);
    matrix.set(parentMatrix);
    matrix.preTranslate(0, -documentData.baselineShift * Utils.dpScale());
    matrix.preScale(fontScale, fontScale);
    path.transform(matrix);
    if (documentData.strokeOverFill) {
      drawGlyph(path, fillPaint, canvas);
      drawGlyph(path, strokePaint, canvas);
    } else {
      drawGlyph(path, strokePaint, canvas);
      drawGlyph(path, fillPaint, canvas);
    }
  }
}

 void _drawGlyph(Path path, Paint paint, Canvas canvas) {
  if (paint.getColor() == Color.TRANSPARENT) {
    return;
  }
  if (paint.getStyle() == Paint.Style.STROKE && paint.getStrokeWidth() == 0) {
    return;
  }
  canvas.drawPath(path, paint);
}

 void _drawCharacterFromFont(String character, DocumentData documentData, Canvas canvas) {
  if (documentData.strokeOverFill) {
    drawCharacter(character, fillPaint, canvas);
    drawCharacter(character, strokePaint, canvas);
  } else {
    drawCharacter(character, strokePaint, canvas);
    drawCharacter(character, fillPaint, canvas);
  }
}

 void _drawCharacter(String character, Paint paint, Canvas canvas) {
  if (paint.getColor() == Color.TRANSPARENT) {
    return;
  }
  if (paint.getStyle() == Paint.Style.STROKE && paint.getStrokeWidth() == 0) {
    return;
  }
  canvas.drawText(character, 0, character.length(), 0, 0, paint);
}

 List<ContentGroup> _getContentsForCharacter(FontCharacter character) {
  if (contentsForCharacter.containsKey(character)) {
    return contentsForCharacter.get(character);
  }
  List<ShapeGroup> shapes = character.getShapes();
  int size = shapes.size();
  List<ContentGroup> contents = new ArrayList<>(size);
  for (int i = 0; i < size; i++) {
    ShapeGroup sg = shapes.get(i);
    contents.add(new ContentGroup(lottieDrawable, this, sg));
  }
  contentsForCharacter.put(character, contents);
  return contents;
}

 String _codePointToString(String text, int startIndex) {
  int firstCodePoint = text.codePointAt(startIndex);
  int firstCodePointLength = Character.charCount(firstCodePoint);
  int key = firstCodePoint;
  int index = startIndex + firstCodePointLength;
  while (index < text.length()) {
    int nextCodePoint = text.codePointAt(index);
    if (!isModifier(nextCodePoint)) {
      break;
    }
    int nextCodePointLength = Character.charCount(nextCodePoint);
    index += nextCodePointLength;
    key = key * 31 + nextCodePoint;
  }

  if (codePointCache.containsKey(key)) {
    return codePointCache.get(key);
  }

  stringBuilder.setLength(0);
  for (int i = startIndex; i < index; ) {
    int codePoint = text.codePointAt(i);
    stringBuilder.appendCodePoint(codePoint);
    i += Character.charCount(codePoint);
  }
  String str = stringBuilder.toString();
  codePointCache.put(key, str);
  return str;
}

 bool _isModifier(int codePoint) {
  return Character.getType(codePoint) == Character.FORMAT ||
      Character.getType(codePoint) == Character.MODIFIER_SYMBOL ||
      Character.getType(codePoint) == Character.NON_SPACING_MARK ||
      Character.getType(codePoint) == Character.OTHER_SYMBOL ||
      Character.getType(codePoint) == Character.SURROGATE;
}

@override
 void addValueCallback<T>(T property,  LottieValueCallback<T>/*?*/ callback) {
  super.addValueCallback(property, callback);
  if (property == LottieProperty.color) {
    if (_colorCallbackAnimation != null) {
      removeAnimation(_colorCallbackAnimation);
    }

    if (callback == null) {
      _colorCallbackAnimation = null;
    } else {
      _colorCallbackAnimation = new ValueCallbackKeyframeAnimation<>((LottieValueCallback<Integer>) callback);
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
      _strokeColorCallbackAnimation = new ValueCallbackKeyframeAnimation<>((LottieValueCallback<Integer>) callback);
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
      _strokeWidthCallbackAnimation = new ValueCallbackKeyframeAnimation<>((LottieValueCallback<Float>) callback);
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
      _trackingCallbackAnimation = new ValueCallbackKeyframeAnimation<>((LottieValueCallback<Float>) callback);
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
      _textSizeCallbackAnimation = new ValueCallbackKeyframeAnimation<>((LottieValueCallback<Float>) callback);
      _textSizeCallbackAnimation.addUpdateListener(invalidateSelf);
      addAnimation(_textSizeCallbackAnimation);
    }
  }
}
}