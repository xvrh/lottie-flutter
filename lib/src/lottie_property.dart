import 'dart:ui';

/// Property values are the same type as the generic type of their corresponding
/// {@link LottieValueCallback}. With this, we can use generics to maintain type safety
/// of the callbacks.
///
/// Supported properties:
/// Transform:
///    {@link #TRANSFORM_ANCHOR_POINT}
///    {@link #TRANSFORM_POSITION}
///    {@link #TRANSFORM_OPACITY}
///    {@link #TRANSFORM_SCALE}
///    {@link #TRANSFORM_ROTATION}
///    {@link #TRANSFORM_SKEW}
///    {@link #TRANSFORM_SKEW_ANGLE}
///
/// Fill:
///    {@link #COLOR} (non-gradient)
///    {@link #OPACITY}
///    {@link #COLOR_FILTER}
///
/// Stroke:
///    {@link #COLOR} (non-gradient)
///    {@link #STROKE_WIDTH}
///    {@link #OPACITY}
///    {@link #COLOR_FILTER}
///
/// Ellipse:
///    {@link #POSITION}
///    {@link #ELLIPSE_SIZE}
///
/// Polystar:
///    {@link #POLYSTAR_POINTS}
///    {@link #POLYSTAR_ROTATION}
///    {@link #POSITION}
///    {@link #POLYSTAR_INNER_RADIUS} (star)
///    {@link #POLYSTAR_OUTER_RADIUS}
///    {@link #POLYSTAR_INNER_ROUNDEDNESS} (star)
///    {@link #POLYSTAR_OUTER_ROUNDEDNESS}
///
/// Repeater:
///    All transform properties
///    {@link #REPEATER_COPIES}
///    {@link #REPEATER_OFFSET}
///    {@link #TRANSFORM_ROTATION}
///    {@link #TRANSFORM_START_OPACITY}
///    {@link #TRANSFORM_END_OPACITY}
///
/// Layers:
///    All transform properties
///    {@link #TIME_REMAP} (composition layers only)
abstract class LottieProperty {
  /// ColorInt **/
  static const Color color = Color(0x00000001);
  static const Color strokeColor = Color(0x00000002);

  /// Opacity value are 0-100 to match after effects **/
  static const int transformOpacity = 3;

  /// [0,100] */
  static const int opacity = 4;

  /// In Px */
  static const Offset transformAnchorPoint = Offset(5, 5);

  /// In Px */
  static const Offset transformPosition = Offset(6, 6);

  /// In Px */
  static const Offset ellipseSize = Offset(7, 7);

  /// In Px */
  static const Offset rectangleSize = Offset(8, 8);

  /// In degrees */
  static const double cornerRadius = 9.0;

  /// In Px */
  static const Offset position = Offset(10, 10);
  static const Offset transformScale = Offset(11, 11);

  /// In degrees */
  static const double transformRotation = 12.0;

  /// 0-85 */
  static const double transformSkew = 13.0;

  /// In degrees */
  static const double transformSkewAngle = 14.0;

  /// In Px */
  static const double strokeWidth = 15.0;
  static const double textTracking = 16.0;
  static const double repeaterCopies = 17.0;
  static const double repeaterOffset = 18.0;
  static const double polystarPoints = 19.0;

  /// In degrees */
  static const double polystarRotation = 20.0;

  /// In Px */
  static const double polystarInnerRadius = 21.0;

  /// In Px */
  static const double polystarOuterRadius = 22.0;

  /// [0,100] */
  static const double polystarInnerRoundedness = 23.0;

  /// [0,100] */
  static const double polystarOuterRoundedness = 24.0;

  /// [0,100] */
  static const double transformStartOpacity = 25.0;

  /// [0,100] */
  static const double transformEndOpacity = 26.0;

  /// The time value in seconds */
  static const double timeRemap = 27.0;

  /// In Dp
  static const double textSize = 28.0;

  static const ColorFilter colorFilter =
      ColorFilter.mode(Color(0xFF000000), BlendMode.dst);

  static final List<Color> gradientColor = [];
}
