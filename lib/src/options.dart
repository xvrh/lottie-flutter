class LottieOptions {
  /// Enable merge path support.
  ///
  /// Merge paths currently don't work if the the operand shape is entirely contained within the
  /// first shape. If you need to cut out one shape from another shape, use an even-odd fill type
  /// instead of using merge paths.
  final bool enableMergePaths;

  /// Enable layer-level opacity.
  ///
  /// Add the ability to render opacity on the layer level rather than the shape level.
  /// Opacity is normally applied directly to a shape. In cases where translucent shapes overlap,
  /// applying opacity to a layer will be more accurate at the expense of performance.
  /// Details: https://github.com/airbnb/lottie-android/issues/902
  final bool enableApplyingOpacityToLayers;

  LottieOptions({
    this.enableMergePaths = false,
    this.enableApplyingOpacityToLayers = false,
  });
}
