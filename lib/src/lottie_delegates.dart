import 'package:flutter/widgets.dart';

import 'lottie_drawable.dart';
import 'value_delegate.dart';

// TODO(xha): recognize style Bold, Medium, Regular, SemiBold, etc...
TextStyle _defaultTextStyleDelegate(LottieFontStyle font) =>
    TextStyle(fontFamily: font.font);

@immutable
class LottieDelegates {
  /// Specify a callback to dynamically changes the text displayed in the lottie
  /// animation.
  final String Function(String) /*?*/ text;

  /// A callback to map between a font family specified in the json animation
  /// and the font family in your assets.
  /// This is useful either if:
  ///  - you want to dynamically change the font used
  ///  - the name of the font in your asset doesn't match the one in the json file.
  ///
  /// If the callback is null, the font family from the json is used as it.
  final TextStyle Function(LottieFontStyle) textStyle;

  final List<ValueDelegate> values;

  //TODO(xha): imageDelegate, valueCallback

  LottieDelegates({
    this.text,
    TextStyle Function(LottieFontStyle) textStyle,
    this.values,
  }) : textStyle = textStyle ?? _defaultTextStyleDelegate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LottieDelegates &&
          text == other.text &&
          textStyle == other.textStyle &&
          values == other.values;

  @override
  int get hashCode => hashValues(text, textStyle, values);
}
