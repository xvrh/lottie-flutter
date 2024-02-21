import 'package:flutter/widgets.dart';
import 'lottie_drawable.dart';
import 'lottie_property.dart';
import 'model/key_path.dart';
import 'utils.dart';
import 'value/drop_shadow.dart';
import 'value/lottie_frame_info.dart';
import 'value/lottie_relative_double_value_callback.dart';
import 'value/lottie_relative_integer_value_callback.dart';
import 'value/lottie_relative_point_value_callback.dart';
import 'value/lottie_value_callback.dart';

class ValueDelegate<T> {
  final List<String> keyPath;
  final T property;
  final T? value;
  final T Function(LottieFrameInfo<T>)? callback;

  ValueDelegate._(this.keyPath, this.property, this.value, this.callback)
      : assert(value == null || callback == null,
            "Value and callback can't be both specified.");

  int get callbackHash => callback.hashCode;

  static ValueDelegate<Offset> _offset(
      List<String> keyPath,
      Offset property,
      Offset? value,
      Offset Function(LottieFrameInfo<Offset>)? callback,
      Offset? relative) {
    if (relative != null) {
      assert(callback == null);
      callback = relativeOffsetValueCallback(relative);
    }
    return ValueDelegate<Offset>._(keyPath, property, value, callback);
  }

  static ValueDelegate<double> _double(
      List<String> keyPath,
      double property,
      double? value,
      double Function(LottieFrameInfo<double>)? callback,
      double? relative) {
    if (relative != null) {
      assert(callback == null);
      callback = relativeDoubleValueCallback(relative);
    }
    return ValueDelegate<double>._(keyPath, property, value, callback);
  }

  static ValueDelegate<int> _int(List<String> keyPath, int property, int? value,
      int Function(LottieFrameInfo<int>)? callback, int? relative) {
    if (relative != null) {
      assert(callback == null);
      callback = relativeIntegerValueCallback(relative);
    }
    return ValueDelegate<int>._(keyPath, property, value, callback);
  }

  static ValueDelegate<Color> color(List<String> keyPath,
          {Color? value, Color Function(LottieFrameInfo<Color>)? callback}) =>
      ValueDelegate._(keyPath, LottieProperty.color, value, callback);

  static ValueDelegate<Color> strokeColor(List<String> keyPath,
          {Color? value, Color Function(LottieFrameInfo<Color>)? callback}) =>
      ValueDelegate._(keyPath, LottieProperty.strokeColor, value, callback);

  /// Opacity value are 0-100 to match after effects
  static ValueDelegate<int> transformOpacity(List<String> keyPath,
          {int? value,
          int Function(LottieFrameInfo<int>)? callback,
          int? relative}) =>
      _int(keyPath, LottieProperty.transformOpacity, value, callback, relative);

  /// Opacity value are 0-100 to match after effects
  static ValueDelegate<int> opacity(List<String> keyPath,
          {int? value,
          int Function(LottieFrameInfo<int>)? callback,
          int? relative}) =>
      _int(keyPath, LottieProperty.opacity, value, callback, relative);

  static ValueDelegate<Offset> transformAnchorPoint(
    List<String> keyPath, {
    Offset? value,
    Offset Function(LottieFrameInfo<Offset>)? callback,
    Offset? relative,
  }) {
    return _offset(keyPath, LottieProperty.transformAnchorPoint, value,
        callback, relative);
  }

  static ValueDelegate<Offset> transformPosition(
    List<String> keyPath, {
    Offset? value,
    Offset Function(LottieFrameInfo<Offset>)? callback,
    Offset? relative,
  }) =>
      _offset(
          keyPath, LottieProperty.transformPosition, value, callback, relative);

  static ValueDelegate<Offset> ellipseSize(
    List<String> keyPath, {
    Offset? value,
    Offset Function(LottieFrameInfo<Offset>)? callback,
    Offset? relative,
  }) =>
      _offset(keyPath, LottieProperty.ellipseSize, value, callback, relative);

  static ValueDelegate<Offset> rectangleSize(
    List<String> keyPath, {
    Offset? value,
    Offset Function(LottieFrameInfo<Offset>)? callback,
    Offset? relative,
  }) =>
      _offset(keyPath, LottieProperty.rectangleSize, value, callback, relative);

  static ValueDelegate<double> cornerRadius(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.cornerRadius, value, callback, relative);

  static ValueDelegate<Offset> position(
    List<String> keyPath, {
    Offset? value,
    Offset Function(LottieFrameInfo<Offset>)? callback,
    Offset? relative,
  }) =>
      _offset(keyPath, LottieProperty.position, value, callback, relative);

  static ValueDelegate<Offset> transformScale(
    List<String> keyPath, {
    Offset? value,
    Offset Function(LottieFrameInfo<Offset>)? callback,
    Offset? relative,
  }) =>
      _offset(
          keyPath, LottieProperty.transformScale, value, callback, relative);

  /// In degrees
  static ValueDelegate<double> transformRotation(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(
          keyPath, LottieProperty.transformRotation, value, callback, relative);

  static ValueDelegate<double> transformSkew(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.transformSkew, value, callback, relative);

  static ValueDelegate<double> transformSkewAngle(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.transformSkewAngle, value, callback,
          relative);

  static ValueDelegate<double> strokeWidth(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.strokeWidth, value, callback, relative);

  static ValueDelegate<double> textTracking(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.textTracking, value, callback, relative);

  static ValueDelegate<double> repeaterCopies(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(
          keyPath, LottieProperty.repeaterCopies, value, callback, relative);

  static ValueDelegate<double> repeaterOffset(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(
          keyPath, LottieProperty.repeaterOffset, value, callback, relative);

  static ValueDelegate<double> polystarPoints(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(
          keyPath, LottieProperty.polystarPoints, value, callback, relative);

  /// In degrees
  static ValueDelegate<double> polystarRotation(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(
          keyPath, LottieProperty.polystarRotation, value, callback, relative);

  static ValueDelegate<double> polystarInnerRadius(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.polystarInnerRadius, value, callback,
          relative);

  static ValueDelegate<double> polystarOuterRadius(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.polystarOuterRadius, value, callback,
          relative);

  static ValueDelegate<double> polystarInnerRoundedness(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.polystarInnerRoundedness, value, callback,
          relative);

  static ValueDelegate<double> polystarOuterRoundedness(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.polystarOuterRoundedness, value, callback,
          relative);

  /// Opacity value are 0-100 to match after effects
  static ValueDelegate<double> transformStartOpacity(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.transformStartOpacity, value, callback,
          relative);

  /// Opacity value are 0-100 to match after effects
  static ValueDelegate<double> transformEndOpacity(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.transformEndOpacity, value, callback,
          relative);

  /// The time value in seconds
  static ValueDelegate<double> timeRemap(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.timeRemap, value, callback, relative);

  static ValueDelegate<double> textSize(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback,
          double? relative}) =>
      _double(keyPath, LottieProperty.textSize, value, callback, relative);

  static ValueDelegate<String> text(List<String> keyPath,
          {String? value,
          String Function(LottieFrameInfo<String>)? callback}) =>
      ValueDelegate._(keyPath, LottieProperty.text, value, callback);

  static ValueDelegate<ColorFilter> colorFilter(List<String> keyPath,
          {ColorFilter? value,
          ColorFilter Function(LottieFrameInfo<ColorFilter>)? callback}) =>
      ValueDelegate._(keyPath, LottieProperty.colorFilter, value, callback);

  static ValueDelegate<List<Color>> gradientColor(List<String> keyPath,
          {List<Color>? value,
          List<Color> Function(LottieFrameInfo<List<Color>>)? callback}) =>
      ValueDelegate._(keyPath, LottieProperty.gradientColor, value, callback);

  static ValueDelegate<double> blurRadius(List<String> keyPath,
          {double? value,
          double Function(LottieFrameInfo<double>)? callback}) =>
      ValueDelegate._(keyPath, LottieProperty.blurRadius, value, callback);

  static ValueDelegate<DropShadow> dropShadow(List<String> keyPath,
          {DropShadow? value,
          DropShadow Function(LottieFrameInfo<DropShadow>)? callback}) =>
      ValueDelegate._(keyPath, LottieProperty.dropShadow, value, callback);

  ResolvedValueDelegate<T>? _resolved;
  ResolvedValueDelegate _resolve(List<KeyPath> resolvedPaths) {
    _resolved = ResolvedValueDelegate<T>(this, resolvedPaths);
    return _resolved!;
  }

  bool isSameProperty(ValueDelegate other) {
    if (identical(this, other)) return true;
    return other is ValueDelegate<T> &&
        const ListEquality<String>().equals(other.keyPath, keyPath) &&
        other.property == property;
  }
}

ResolvedValueDelegate internalResolved(ValueDelegate valueDelegate) {
  return valueDelegate._resolved!;
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
      ..setValue(delegate.value)
      ..callback = delegate.callback;
  }

  void clear() {
    valueCallback
      ..setValue(null)
      ..callback = null;
  }

  /// Add a property callback for the specified {@link KeyPath}. This {@link KeyPath} can resolve
  /// to multiple contents. In that case, the callbacks's value will apply to all of them.
  /// <p>
  /// Internally, this will check if the {@link KeyPath} has already been resolved with
  /// {#resolveKeyPath(KeyPath)} and will resolve it if it hasn't.
  void addValueCallback(LottieDrawable drawable) {
    var invalidate = false;
    if (valueDelegate.keyPath.isEmpty) {
      drawable.compositionLayer.addValueCallback(property, valueCallback);
      invalidate = true;
    } else {
      for (var keyPath in keyPaths) {
        keyPath.resolvedElement!.addValueCallback<T>(property, valueCallback);
        invalidate = true;
      }
    }
    if (invalidate) {
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
