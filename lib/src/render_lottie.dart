import 'package:flutter/rendering.dart';
import 'composition.dart';
import 'frame_rate.dart';
import 'lottie_delegates.dart';
import 'lottie_drawable.dart';
import 'render_cache.dart';

/// A Lottie animation in the render tree.
///
/// The RenderLottie attempts to find a size for itself that fits in the given
/// constraints and preserves the composition's intrinsic aspect ratio.
class RenderLottie extends RenderBox {
  RenderLottie({
    required LottieComposition? composition,
    LottieDelegates? delegates,
    bool? enableMergePaths,
    bool? enableApplyingOpacityToLayers,
    double progress = 0.0,
    FrameRate? frameRate,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    FilterQuality? filterQuality,
    RenderCache? renderCache,
    required double devicePixelRatio,
  })  : assert(progress >= 0.0 && progress <= 1.0),
        assert(
            renderCache == null || frameRate != FrameRate.max,
            'FrameRate.max cannot be used with a RenderCache '
            'Use a specific frame rate. e.g. FrameRate(60)'),
        _drawable = composition != null
            ? (LottieDrawable(composition, frameRate: frameRate)
              ..setProgress(progress)
              ..delegates = delegates
              ..enableMergePaths = enableMergePaths ?? false
              ..isApplyingOpacityToLayersEnabled =
                  enableApplyingOpacityToLayers ?? false
              ..filterQuality = filterQuality)
            : null,
        _width = width,
        _height = height,
        _fit = fit,
        _alignment = alignment,
        _renderCache = renderCache,
        _devicePixelRatio = devicePixelRatio;

  /// The lottie composition to display.
  LottieComposition? get composition => _drawable?.composition;
  LottieDrawable? _drawable;

  void setComposition(LottieComposition? composition,
      {required double progress,
      required FrameRate? frameRate,
      required LottieDelegates? delegates,
      bool? enableMergePaths,
      bool? enableApplyingOpacityToLayers,
      FilterQuality? filterQuality}) {
    var drawable = _drawable;
    enableMergePaths ??= false;
    enableApplyingOpacityToLayers ??= false;

    var needsLayout = false;
    var needsPaint = false;
    if (composition == null) {
      if (drawable != null) {
        drawable = _drawable = null;
        needsPaint = true;
        needsLayout = true;
      }
    } else {
      if (drawable == null ||
          drawable.composition != composition ||
          drawable.frameRate != frameRate) {
        drawable =
            _drawable = LottieDrawable(composition, frameRate: frameRate);
        needsLayout = true;
        needsPaint = true;
      }

      needsPaint |= drawable.setProgress(progress);

      if (drawable.delegates != delegates) {
        drawable.delegates = delegates;
        needsPaint = true;
      }
      if (enableMergePaths != drawable.enableMergePaths) {
        drawable.enableMergePaths = enableMergePaths;
        needsPaint = true;
      }
      if (enableApplyingOpacityToLayers !=
          drawable.isApplyingOpacityToLayersEnabled) {
        drawable.isApplyingOpacityToLayersEnabled =
            enableApplyingOpacityToLayers;
        needsPaint = true;
      }
      if (filterQuality != drawable.filterQuality) {
        drawable.filterQuality = filterQuality;
        needsPaint = true;
      }
    }

    if (needsPaint) {
      markNeedsPaint();
    }
    if (needsLayout && (_width == null || _height == null)) {
      markNeedsLayout();
    }
  }

  /// If non-null, requires the composition to have this width.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  double? get width => _width;
  double? _width;

  set width(double? value) {
    if (value == _width) {
      return;
    }
    _width = value;
    markNeedsLayout();
  }

  /// If non-null, require the composition to have this height.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  double? get height => _height;
  double? _height;

  set height(double? value) {
    if (value == _height) {
      return;
    }
    _height = value;
    markNeedsLayout();
  }

  /// How to inscribe the composition into the space allocated during layout.
  BoxFit? get fit => _fit;
  BoxFit? _fit;
  set fit(BoxFit? value) {
    if (value == _fit) {
      return;
    }
    _fit = value;
    markNeedsPaint();
  }

  /// How to align the composition within its bounds.
  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;

  set alignment(AlignmentGeometry value) {
    if (value == _alignment) {
      return;
    }
    _alignment = value;
    markNeedsPaint();
  }

  RenderCache? get renderCache => _renderCache;
  RenderCache? _renderCache;
  set renderCache(RenderCache? value) {
    if (value == _renderCache) {
      return;
    }
    _renderCache?.release(this);
    _renderCache = value;
    markNeedsPaint();
  }

  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  /// Find a size for the render composition within the given constraints.
  ///
  ///  - The dimensions of the RenderLottie must fit within the constraints.
  ///  - The aspect ratio of the RenderLottie matches the intrinsic aspect
  ///    ratio of the Lottie animation.
  ///  - The RenderLottie's dimension are maximal subject to being smaller than
  ///    the intrinsic size of the composition.
  Size _sizeForConstraints(BoxConstraints constraints) {
    // Folds the given |width| and |height| into |constraints| so they can all
    // be treated uniformly.
    constraints = BoxConstraints.tightFor(
      width: _width,
      height: _height,
    ).enforce(constraints);

    if (_drawable == null) {
      return constraints.smallest;
    }

    return constraints
        .constrainSizeAndAttemptToPreserveAspectRatio(_drawable!.size);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(height >= 0.0);
    if (_width == null && _height == null) {
      return 0.0;
    }
    return _sizeForConstraints(BoxConstraints.tightForFinite(height: height))
        .width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(height >= 0.0);
    return _sizeForConstraints(BoxConstraints.tightForFinite(height: height))
        .width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(width >= 0.0);
    if (_width == null && _height == null) {
      return 0.0;
    }
    return _sizeForConstraints(BoxConstraints.tightForFinite(width: width))
        .height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(width >= 0.0);
    return _sizeForConstraints(BoxConstraints.tightForFinite(width: width))
        .height;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _sizeForConstraints(constraints);
  }

  @override
  void performLayout() {
    size = _sizeForConstraints(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_drawable == null) return;

    RenderCacheContext? cacheContext;
    if (_renderCache case var renderCache?) {
      cacheContext = RenderCacheContext(
        cache: renderCache.acquire(this),
        devicePixelRatio: _devicePixelRatio,
        renderBox: this,
      );
    }

    _drawable!.draw(
      context.canvas,
      offset & size,
      fit: _fit,
      alignment: _alignment.resolve(TextDirection.ltr),
      renderCache: cacheContext,
    );
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

  @override
  void dispose() {
    _renderCache?.release(this);
    super.dispose();
  }
}
