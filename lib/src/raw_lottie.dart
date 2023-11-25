import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'composition.dart';
import 'frame_rate.dart';
import 'lottie_delegates.dart';
import 'lottie_drawable.dart';
import 'options.dart';
import 'render_lottie.dart';

/// A widget that displays a [LottieDrawable] directly.
///
/// This widget is rarely used directly. Instead, consider using [Lottie].
class RawLottie extends LeafRenderObjectWidget {
  /// Creates a widget that displays a Lottie composition.
  const RawLottie({
    super.key,
    this.composition,
    this.delegates,
    this.options,
    double? progress,
    this.frameRate,
    this.width,
    this.height,
    this.fit,
    AlignmentGeometry? alignment,
    this.filterQuality,
    bool? enableRenderCache,
  })  : progress = progress ?? 0.0,
        alignment = alignment ?? Alignment.center,
        enableRenderCache = enableRenderCache ?? false;

  /// The Lottie composition to display.
  final LottieComposition? composition;

  /// Allows to modify the Lottie animation at runtime
  final LottieDelegates? delegates;

  final LottieOptions? options;

  /// The progress of the Lottie animation (between 0.0 and 1.0).
  final double progress;

  /// The number of frames per second to render.
  /// Use `FrameRate.composition` to use the original frame rate of the Lottie composition (default)
  /// Use `FrameRate.max` to advance the animation progression at every frame.
  final FrameRate? frameRate;

  /// If non-null, require the Lottie composition to have this width.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double? width;

  /// If non-null, require the Lottie composition to have this height.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double? height;

  /// How to inscribe the Lottie composition into the space allocated during layout.
  final BoxFit? fit;

  /// How to align the composition within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// Opt-in a special render mode where the frames of the animation are
  /// lazily rendered in offscreen images.
  /// Subsequent runs of the animation will be very cheap to render.
  ///
  /// This is useful is the animation is complex and can consume lot of energy
  /// from the battery.
  /// This is will trade an excessive CPU usage for an increase memory usage.
  ///
  /// The render cache is managed internally and will release the memory once the
  /// animation is disposed. The cache is shared between all animations. If 2 `Lottie`
  /// widget are rendered at the same size, they will render only once.
  ///
  /// Any change in the configuration of the animation (delegates, frame rate etc...)
  /// will clear the cache.
  /// Any change in the size will invalidate the cache. The cache use the final size
  /// visible on the screen (with all transforms applied).
  ///
  /// In order to not exceed the memory limit of a device, the cache is constrained
  /// to maximum 50MB. After that, animations are not cached anymore.
  final bool enableRenderCache;

  final FilterQuality? filterQuality;

  @override
  RenderLottie createRenderObject(BuildContext context) {
    return RenderLottie(
      composition: composition,
      delegates: delegates,
      enableMergePaths: options?.enableMergePaths,
      enableApplyingOpacityToLayers: options?.enableApplyingOpacityToLayers,
      progress: progress,
      frameRate: frameRate,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      enableRenderCache: enableRenderCache,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderLottie renderObject) {
    renderObject
      ..setComposition(
        composition,
        progress: progress,
        frameRate: frameRate,
        delegates: delegates,
        enableMergePaths: options?.enableMergePaths,
        enableApplyingOpacityToLayers: options?.enableApplyingOpacityToLayers,
        filterQuality: filterQuality,
      )
      ..width = width
      ..height = height
      ..alignment = alignment
      ..fit = fit
      ..enableRenderCache = enableRenderCache
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<LottieComposition>('composition', composition));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        defaultValue: null));
  }
}
