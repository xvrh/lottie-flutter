import 'dart:ui';
import 'value/scale_xy.dart';

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
  static final Color color = Color(1);
  static final Color strokeColor = Color(2);

  /// Opacity value are 0-100 to match after effects **/
  static final int transformOpacity = 3;

  /// [0,100] */
  static final int opacity = 4;

  /// In Px */
  static final Offset transformAnchorPoint = Offset.zero;

  /// In Px */
  static final Offset transformPosition = Offset.zero;

  /// In Px */
  static final Offset ellipseSize = Offset.zero;

  /// In Px */
  static final Offset rectangleSize = Offset.zero;

  /// In degrees */
  static final double cornerRadius = 0.0;

  /// In Px */
  static final Offset position = Offset.zero;
  static final ScaleXY transformScale = ScaleXY.one();

  /// In degrees */
  static final double transformRotation = 1.0;

  /// 0-85 */
  static final double transformSkew = 0.0;

  /// In degrees */
  static final double transformSkewAngle = 0.0;

  /// In Px */
  static final double strokeWidth = 2.0;
  static final double textTracking = 3.0;
  static final double repeaterCopies = 4.0;
  static final double repeaterOffset = 5.0;
  static final double polystarPoints = 6.0;

  /// In degrees */
  static final double polystarRotation = 7.0;

  /// In Px */
  static final double polystarInnerRadius = 8.0;

  /// In Px */
  static final double polystarOuterRadius = 9.0;

  /// [0,100] */
  static final double polystarInnerRoundedness = 10.0;

  /// [0,100] */
  static final double polystarOuterRoundedness = 11.0;

  /// [0,100] */
  static final double transformStartOpacity = 12.0;

  /// [0,100] */
  static final double transformEndOpacity = 12.1;

  /// The time value in seconds */
  static final double timeRemap = 13.0;

  /// In Dp */
  static final double textSize = 14.0;

  static final ColorFilter colorFilter =
      ColorFilter.mode(Color(0xFF000000), BlendMode.dst);

  static final List<Color> gradientColor = const [];
}
