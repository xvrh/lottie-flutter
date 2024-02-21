import 'dart:ui';
import 'value/drop_shadow.dart';

/// Property values are the same type as the generic type of their corresponding
/// [LottieValueCallback]. With this, we can use generics to maintain type safety
/// of the callbacks.
///
/// Supported properties:
/// Transform:
///    {TRANSFORM_ANCHOR_POINT}
///    {TRANSFORM_POSITION}
///    {TRANSFORM_OPACITY}
///    {TRANSFORM_SCALE}
///    {TRANSFORM_ROTATION}
///    {TRANSFORM_SKEW}
///    {TRANSFORM_SKEW_ANGLE}
///
/// Fill:
///    {#COLOR} (non-gradient)
///    {#OPACITY}
///    {#COLOR_FILTER}
///
/// Stroke:
///    {#COLOR} (non-gradient)
///    {#STROKE_WIDTH}
///    {#OPACITY}
///    {#COLOR_FILTER}
///
/// Ellipse:
///    {#POSITION}
///    {#ELLIPSE_SIZE}
///
/// Polystar:
///    {#POLYSTAR_POINTS}
///    {#POLYSTAR_ROTATION}
///    {#POSITION}
///    {#POLYSTAR_INNER_RADIUS} (star)
///    {#POLYSTAR_OUTER_RADIUS}
///    {#POLYSTAR_INNER_ROUNDEDNESS} (star)
///    {#POLYSTAR_OUTER_ROUNDEDNESS}
///
/// Repeater:
///    All transform properties
///    {#REPEATER_COPIES}
///    {#REPEATER_OFFSET}
///    {#TRANSFORM_ROTATION}
///    {#TRANSFORM_START_OPACITY}
///    {#TRANSFORM_END_OPACITY}
///
/// Layers:
///    All transform properties
///    {#TIME_REMAP} (composition layers only)
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

  /// In Px
  static const double blurRadius = 29.0;

  static const dropShadow = DropShadow(
      color: Color(0x00000000), direction: 0, distance: 0, radius: 0);

  /// Set the color filter for an entire drawable content. Can be applied to fills, strokes, images, and solids.
  static const ColorFilter colorFilter =
      ColorFilter.mode(Color(0xFF000000), BlendMode.dst);

  static final List<Color> gradientColor = [];

  /// Replace the text for a text layer.
  static const text = 'dynamic_text';
}
