import 'package:flutter/widgets.dart';
import 'lottie_drawable.dart';
import 'value_delegate.dart';

// TODO(xha): recognize style Bold, Medium, Regular, SemiBold, etc...
TextStyle defaultTextStyleDelegate(LottieFontStyle font) =>
    TextStyle(fontFamily: font.fontFamily);

@immutable
class LottieDelegates {
  /// Specify a callback to dynamically changes the text displayed in the lottie
  /// animation.
  /// For instance, this is useful when you want to translate the text in the animation.
  final String Function(String) /*?*/ text;

  /// A callback to map between a font family specified in the json animation
  /// with the font family in your assets.
  /// This is useful either if:
  ///  - the name of the font in your asset doesn't match the one in the json file.
  ///  - you want to use an other font than the one declared in the json
  ///
  /// If the callback is null, the font family from the json is used as it.
  ///
  /// Given an object containing the font family and style specified in the json
  /// return a configured `TextStyle` that will be used as the base style when
  /// painting the text.
  final TextStyle Function(LottieFontStyle) textStyle;

  /// A list of value delegates to dynamically modify the animation
  /// properties at runtime.
  ///
  /// Example:
  /// ```dart
  /// Lottie.asset(
  ///   'lottiefile.json',
  ///   delegates: LottieDelegates(
  ///     value: [
  ///       ValueDelegate.color(['lake', 'fill'], value: Colors.blue),
  ///       ValueDelegate.opacity(['**', 'fill'], callback: (frameInfo) => 0.5 * frameInfo.overallProgress),
  ///     ],
  ///   ),
  /// );
  /// ```
  final List<ValueDelegate> values;

  //TODO(xha): imageDelegate to change the image to display?

  LottieDelegates({
    this.text,
    TextStyle Function(LottieFontStyle) textStyle,
    this.values,
  }) : textStyle = textStyle;

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
