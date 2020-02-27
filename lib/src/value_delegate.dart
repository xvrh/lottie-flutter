import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'lottie_drawable.dart';
import 'lottie_property.dart';
import 'model/key_path.dart';
import 'value/lottie_frame_info.dart';
import 'value/lottie_value_callback.dart';

class ValueDelegate<T> {
  final List<String> keyPath;
  final T property;
  final T value;
  final T Function(LottieFrameInfo<T>) callback;

  ValueDelegate._(this.keyPath, this.property, this.value, this.callback)
      : assert(value == null || callback == null,
            "Value and callback can't be both specified.");

  static ValueDelegate<Color> color(List<String> keyPath,
          {Color value, Color Function(LottieFrameInfo<Color>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.color, value, callback);

  static ValueDelegate<Color> strokeColor(List<String> keyPath,
          {Color value, Color Function(LottieFrameInfo<Color>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.strokeColor, value, callback);

  static ValueDelegate<int> transformOpacity(List<String> keyPath,
          {int value, int Function(LottieFrameInfo<int>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.transformOpacity, value, callback);

  static ValueDelegate<int> opacity(List<String> keyPath,
          {int value, int Function(LottieFrameInfo<int>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.opacity, value, callback);

  static ValueDelegate<Offset> transformAnchorPoint(List<String> keyPath,
          {Offset value, Offset Function(LottieFrameInfo<Offset>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.transformAnchorPoint, value, callback);

  static ValueDelegate<Offset> transformPosition(List<String> keyPath,
          {Offset value, Offset Function(LottieFrameInfo<Offset>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.transformPosition, value, callback);

  static ValueDelegate<Offset> ellipseSize(List<String> keyPath,
          {Offset value, Offset Function(LottieFrameInfo<Offset>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.ellipseSize, value, callback);

  static ValueDelegate<Offset> rectangleSize(List<String> keyPath,
          {Offset value, Offset Function(LottieFrameInfo<Offset>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.rectangleSize, value, callback);

  static ValueDelegate<double> cornerRadius(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.cornerRadius, value, callback);

  static ValueDelegate<Offset> position(List<String> keyPath,
          {Offset value, Offset Function(LottieFrameInfo<Offset>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.position, value, callback);

  static ValueDelegate<Offset> transformScale(List<String> keyPath,
          {Offset value, Offset Function(LottieFrameInfo<Offset>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.transformScale, value, callback);

  static ValueDelegate<double> transformRotation(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.transformRotation, value, callback);

  static ValueDelegate<double> transformSkew(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.transformSkew, value, callback);

  static ValueDelegate<double> transformSkewAngle(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.transformSkewAngle, value, callback);

  static ValueDelegate<double> strokeWidth(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.strokeWidth, value, callback);

  static ValueDelegate<double> textTracking(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.textTracking, value, callback);

  static ValueDelegate<double> repeaterCopies(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.repeaterCopies, value, callback);

  static ValueDelegate<double> repeaterOffset(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.repeaterOffset, value, callback);

  static ValueDelegate<double> polystarPoints(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.polystarPoints, value, callback);

  static ValueDelegate<double> polystarRotation(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.polystarRotation, value, callback);

  static ValueDelegate<double> polystarInnerRadius(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.polystarInnerRadius, value, callback);

  static ValueDelegate<double> polystarOuterRadius(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.polystarOuterRadius, value, callback);

  static ValueDelegate<double> polystarInnerRoundedness(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.polystarInnerRoundedness, value, callback);

  static ValueDelegate<double> polystarOuterRoundedness(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.polystarOuterRoundedness, value, callback);

  static ValueDelegate<double> transformStartOpacity(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.transformStartOpacity, value, callback);

  static ValueDelegate<double> transformEndOpacity(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(
          keyPath, LottieProperty.transformEndOpacity, value, callback);

  static ValueDelegate<double> timeRemap(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.timeRemap, value, callback);

  static ValueDelegate<double> textSize(List<String> keyPath,
          {double value, double Function(LottieFrameInfo<double>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.textSize, value, callback);

  static ValueDelegate<ColorFilter> colorFilter(List<String> keyPath,
          {ColorFilter value,
          ColorFilter Function(LottieFrameInfo<ColorFilter>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.colorFilter, value, callback);

  static ValueDelegate<List<Color>> gradientColor(List<String> keyPath,
          {List<Color> value,
          List<Color> Function(LottieFrameInfo<List<Color>>) callback}) =>
      ValueDelegate._(keyPath, LottieProperty.gradientColor, value, callback);

  ResolvedValueDelegate<T> _resolved;
  ResolvedValueDelegate _resolve(List<KeyPath> resolvedPaths) {
    _resolved = ResolvedValueDelegate<T>(this, resolvedPaths);
    return _resolved;
  }

  bool isSameProperty(ValueDelegate other) {
    if (identical(this, other)) return true;
    return other is ValueDelegate<T> &&
        const ListEquality().equals(other.keyPath, keyPath) &&
        other.property == property;
  }
}

ResolvedValueDelegate internalResolved(ValueDelegate valueDelegate) {
  return valueDelegate._resolved;
}

ResolvedValueDelegate internalResolve(
    ValueDelegate delegate, List<KeyPath> resolvedPaths) {
  return delegate._resolve(resolvedPaths);
}

class ResolvedValueDelegate<T> {
  final ValueDelegate<T> valueDelegate;
  final List<KeyPath> keyPaths;
  final LottieValueCallback<T> valueCallback;

  ResolvedValueDelegate(this.valueDelegate, this.keyPaths)
      : valueCallback = LottieValueCallback(valueDelegate.value)
          ..callback = valueDelegate.callback;

  T get property => valueDelegate.property;

  void updateDelegate(ValueDelegate<T> delegate) {
    valueCallback
      ..value = delegate.value
      ..callback = delegate.callback;
  }

  void clear() {
    valueCallback
      ..value = null
      ..callback = null;
  }

  /// Add a property callback for the specified {@link KeyPath}. This {@link KeyPath} can resolve
  /// to multiple contents. In that case, the callbacks's value will apply to all of them.
  /// <p>
  /// Internally, this will check if the {@link KeyPath} has already been resolved with
  /// {@link #resolveKeyPath(KeyPath)} and will resolve it if it hasn't.
  void addValueCallback(LottieDrawable drawable) {
    for (var keyPath in keyPaths) {
      keyPath.resolvedElement.addValueCallback<T>(property, valueCallback);
    }
    if (keyPaths.isNotEmpty) {
      drawable.invalidateSelf();
      if (property == LottieProperty.timeRemap) {
        // Time remapping values are read in setProgress. In order for the new value
        // to apply, we have to re-set the progress with the current progress so that the
        // time remapping can be reapplied.
        drawable.setProgress(drawable.progress);
      }
    }
  }
}
