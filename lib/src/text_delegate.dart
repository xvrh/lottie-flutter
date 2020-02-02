import 'lottie_drawable.dart';

/// Extend this class to replace animation text with custom text. This can be useful to handle
/// translations.
///
/// The only method you should have to override is {@link #getText(String)}.
class TextDelegate {
  final _stringMap = <String, String>{};
  final LottieDrawable /*?*/ drawable;
  bool _cacheText = true;

  TextDelegate(this.drawable);

  /// Override this to replace the animation text with something dynamic. This can be used for
  /// translations or custom data.
  String getText(String input) {
    return input;
  }

  /// Update the text that will be rendered for the given input text.
  void setText(String input, String output) {
    _stringMap[input] = output;
    _invalidate();
  }

  /// Sets whether or not {@link TextDelegate} will cache (memoize) the results of getText.
  /// If this isn't necessary then set it to false.
  void setCacheText(bool cacheText) {
    _cacheText = cacheText;
  }

  /// Invalidates a cached string with the given input.
  void invalidateText(String input) {
    _stringMap.remove(input);
    _invalidate();
  }

  /// Invalidates all cached strings
  void invalidateAllText() {
    _stringMap.clear();
    _invalidate();
  }

  String getTextInternal(String input) {
    if (_cacheText && _stringMap.containsKey(input)) {
      return _stringMap[input];
    }
    var text = getText(input);
    if (_cacheText) {
      _stringMap[input] = text;
    }
    return text;
  }

  void _invalidate() {
    if (drawable != null) {
      drawable.invalidateSelf();
    }
  }
}
