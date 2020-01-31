import 'package:flutter/rendering.dart';
import '../lottie.dart';
import 'lottie_drawable.dart';

/// A Lottie animation in the render tree.
///
/// The RenderLottie attempts to find a size for itself that fits in the given
/// constraints and preserves the composition's intrinsic aspect ratio.
class RenderLottie extends RenderBox {
  RenderLottie({
    LottieComposition composition,
    double progress = 0.0,
    double width,
    double height,
    BoxFit fit,
    AlignmentGeometry alignment = Alignment.center,
  })  : assert(alignment != null),
        assert(progress != null && progress >= 0.0 && progress <= 1.0),
        _composition = composition,
        _progress = progress,
        _width = width,
        _height = height,
        _fit = fit,
        _alignment = alignment;

  /// The lottie composition to display.
  LottieComposition get composition => _composition;
  LottieComposition _composition;
  set composition(LottieComposition value) {
    if (value == _composition) {
      return;
    }
    _composition = value;
    _drawable = null;
    markNeedsPaint();
    if (_width == null || _height == null) {
      markNeedsLayout();
    }
  }

  double get progress => _progress;
  double _progress;
  set progress(double value) {
    if (value == _progress) {
      return;
    }
    _progress = value;
    markNeedsLayout();
  }

  /// If non-null, requires the composition to have this width.
  ///
  /// If null, the composition will pick a size that best preserves its intrinsic
  /// aspect ratio.
  double get width => _width;
  double _width;
  set width(double value) {
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
  double get height => _height;
  double _height;
  set height(double value) {
    if (value == _height) {
      return;
    }
    _height = value;
    markNeedsLayout();
  }

  /// How to inscribe the composition into the space allocated during layout.
  BoxFit get fit => _fit;
  BoxFit _fit;
  set fit(BoxFit value) {
    if (value == _fit) {
      return;
    }
    _fit = value;
    markNeedsPaint();
  }

  /// How to align the composition within its bounds.
  ///
  /// If this is set to a text-direction-dependent value, [textDirection] must
  /// not be null.
  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    assert(value != null);
    if (value == _alignment) {
      return;
    }
    _alignment = value;
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

    if (_composition == null) {
      return constraints.smallest;
    }

    return constraints.constrainSizeAndAttemptToPreserveAspectRatio(Size(
      _composition.bounds.width.toDouble(),
      _composition.bounds.height.toDouble(),
    ));
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
  void performLayout() {
    size = _sizeForConstraints(constraints);
  }

  LottieDrawable _drawable;
  @override
  void paint(PaintingContext context, Offset offset) {
    if (_composition == null) return;

    _drawable ??= LottieDrawable(_composition);

    _drawable.draw(context.canvas, offset & size,
        progress: _progress,
        fit: _fit,
        alignment: _alignment.resolve(TextDirection.ltr));
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
