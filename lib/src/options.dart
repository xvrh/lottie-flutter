class LottieOptions {
  /// Enable merge path support.
  ///
  /// Merge paths currently don't work if the the operand shape is entirely contained within the
  /// first shape. If you need to cut out one shape from another shape, use an even-odd fill type
  /// instead of using merge paths.
  final bool enableMergePaths;

  LottieOptions({bool enableMergePaths})
      : enableMergePaths = enableMergePaths ?? false;
}
