import 'package:flutter/widgets.dart';

String _defaultFontDelegate(String fontFamily) => fontFamily;

@immutable
class LottieOptions {
  final String Function(String) /*?*/ textDelegate;
  final String Function(String fontFamily) /*?*/ fontDelegate;
  //TODO(xha): imageDelegate, valueCallback

  LottieOptions({
    this.textDelegate,
    String Function(String fontFamily) fontDelegate,
  }) : fontDelegate = fontDelegate ?? _defaultFontDelegate;

  LottieOptions copyWith({
    String Function(String) textDelegate,
    String Function(String fontFamily) fontDelegate,
  }) =>
      LottieOptions(
        textDelegate: textDelegate ?? this.textDelegate,
        fontDelegate: fontDelegate ?? this.fontDelegate,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LottieOptions &&
          textDelegate == other.textDelegate &&
          fontDelegate == other.fontDelegate;

  @override
  int get hashCode => textDelegate.hashCode ^ fontDelegate.hashCode;
}
