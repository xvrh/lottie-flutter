import '../content/text_range_units.dart';
import 'animatable_integer_value.dart';

/// Defines an animated range of text that should have an [AnimatableTextStyle] applied to it.
class AnimatableTextRangeSelector {
  final AnimatableIntegerValue? start;
  final AnimatableIntegerValue? end;
  final AnimatableIntegerValue? offset;
  final TextRangeUnits units;

  AnimatableTextRangeSelector({
    this.start,
    this.end,
    this.offset,
    required this.units,
  });
}
