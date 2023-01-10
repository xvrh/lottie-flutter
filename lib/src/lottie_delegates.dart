import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'composition.dart';
import 'lottie_drawable.dart';
import 'lottie_image_asset.dart';
import 'value_delegate.dart';

TextStyle defaultTextStyleDelegate(LottieFontStyle font) {
  var style = font.style.toLowerCase();

  var fontStyle = style.contains('italic') ? FontStyle.italic : null;

  FontWeight? fontWeight;
  if (style.contains('semibold') || style.contains('semi bold')) {
    fontWeight = FontWeight.w600;
  } else if (style.contains('bold')) {
    fontWeight = FontWeight.bold;
  }
  return TextStyle(
      fontFamily: font.fontFamily,
      fontStyle: fontStyle,
      fontWeight: fontWeight);
}

@immutable
class LottieDelegates {
  /// Specify a callback to dynamically changes the text displayed in the lottie
  /// animation.
  /// For instance, this is useful when you want to translate the text in the animation.
  final String Function(String)? text;

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
  final TextStyle Function(LottieFontStyle)? textStyle;

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
  final List<ValueDelegate>? values;

  /// A callback to dynamically change an image of the animation.
  ///
  /// Example:
  /// ```dart
  /// Lottie.asset(
  //   'assets/data.json',
  //   delegates: LottieDelegates(
  //     image: (composition, image) {
  //       if (image.id == 'img_0' && _isMouseOver) {
  //         return myCustomImage;
  //       }
  //
  //       // Use the default method: composition.images[image.id].loadedImage;
  //       return null;
  //     },
  //   )
  // )
  /// ```
  final ui.Image? Function(LottieComposition, LottieImageAsset)? image;

  const LottieDelegates({
    this.text,
    this.textStyle,
    this.values,
    this.image,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LottieDelegates &&
          text == other.text &&
          textStyle == other.textStyle &&
          values == other.values;

  @override
  int get hashCode => Object.hash(text, textStyle, values);
}
