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
  static final Color COLOR = Color(1);
  static final Color STROKE_COLOR = Color(2);

  /// Opacity value are 0-100 to match after effects **/
  static final int TRANSFORM_OPACITY = 3;

  /// [0,100] */
  static final int OPACITY = 4;

  /// In Px */
  static final Offset TRANSFORM_ANCHOR_POINT = Offset.zero;

  /// In Px */
  static final Offset TRANSFORM_POSITION = Offset.zero;

  /// In Px */
  static final Offset ELLIPSE_SIZE = Offset.zero;

  /// In Px */
  static final Offset RECTANGLE_SIZE = Offset.zero;

  /// In degrees */
  static final double CORNER_RADIUS = 0.0;

  /// In Px */
  static final Offset POSITION = Offset.zero;
  static final ScaleXY TRANSFORM_SCALE = ScaleXY.one();

  /// In degrees */
  static final double TRANSFORM_ROTATION = 1.0;

  /// 0-85 */
  static final double TRANSFORM_SKEW = 0.0;

  /// In degrees */
  static final double TRANSFORM_SKEW_ANGLE = 0.0;

  /// In Px */
  static final double STROKE_WIDTH = 2.0;
  static final double TEXT_TRACKING = 3.0;
  static final double REPEATER_COPIES = 4.0;
  static final double REPEATER_OFFSET = 5.0;
  static final double POLYSTAR_POINTS = 6.0;

  /// In degrees */
  static final double POLYSTAR_ROTATION = 7.0;

  /// In Px */
  static final double POLYSTAR_INNER_RADIUS = 8.0;

  /// In Px */
  static final double POLYSTAR_OUTER_RADIUS = 9.0;

  /// [0,100] */
  static final double POLYSTAR_INNER_ROUNDEDNESS = 10.0;

  /// [0,100] */
  static final double POLYSTAR_OUTER_ROUNDEDNESS = 11.0;

  /// [0,100] */
  static final double TRANSFORM_START_OPACITY = 12.0;

  /// [0,100] */
  static final double TRANSFORM_END_OPACITY = 12.1;

  /// The time value in seconds */
  static final double TIME_REMAP = 13.0;

  /// In Dp */
  static final double TEXT_SIZE = 14.0;

  static final ColorFilter COLOR_FILTER =
      ColorFilter.mode(Color(0xFF000000), BlendMode.dst);

  static final List<Color> GRADIENT_COLOR = const [];
}
