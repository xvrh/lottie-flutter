import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class DropShadow {
  final Color color;
  final double direction;
  final double distance;
  final double radius;

  const DropShadow({
    required this.color,
    required this.direction,
    required this.distance,
    required this.radius,
  });

  DropShadow copyWith(
      {Color? color, double? direction, double? distance, double? radius}) {
    return DropShadow(
      color: color ?? this.color,
      direction: direction ?? this.direction,
      distance: distance ?? this.distance,
      radius: radius ?? this.radius,
    );
  }

  @override
  bool operator ==(other) {
    return other is DropShadow &&
        other.color == color &&
        other.direction == direction &&
        other.distance == distance &&
        other.radius == radius;
  }

  @override
  int get hashCode => Object.hash(color, direction, distance, radius);

  @override
  String toString() => 'DropShadow(color: $color, direction: $direction, '
      'distance: $distance, radius: $radius)';
}
