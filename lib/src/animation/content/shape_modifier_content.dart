import '../../model/content/shape_data.dart';
import 'content.dart';

abstract class ShapeModifierContent extends Content {
  ShapeData modifyShape(ShapeData shapeData);
}
