class Font {
  final String family;
  final String name;
  final String style;
  final double ascent;

  /// Family under which the font file embedded in a .lottie archive is
  /// registered. It is unique to the file so it can't override the app's fonts.
  String? embeddedFamily;

  Font({
    required this.family,
    required this.name,
    required this.style,
    required this.ascent,
  });
}
