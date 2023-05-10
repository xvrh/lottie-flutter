import '../composition.dart';
import '../model/content/content_model.dart';
import 'animatable_transform_parser.dart';
import 'circle_shape_parser.dart';
import 'gradient_fill_parser.dart';
import 'gradient_stroke_parser.dart';
import 'merge_paths_parser.dart';
import 'moshi/json_reader.dart';
import 'polysar_shape_parser.dart';
import 'rectangle_shape_parser.dart';
import 'repeat_parser.dart';
import 'rounded_corners_parser.dart';
import 'shape_fill_parser.dart';
import 'shape_group_parser.dart';
import 'shape_path_parser.dart';
import 'shape_stroke_parser.dart';
import 'shape_trim_path_parser.dart';

class ContentModelParser {
  static final JsonReaderOptions _names = JsonReaderOptions.of(['ty', 'd']);

  ContentModelParser._();

  static ContentModel? parse(JsonReader reader, LottieComposition composition) {
    String? type;

    reader.beginObject();
    // Unfortunately, for an ellipse, d is before "ty" which means that it will get parsed
    // before we are in the ellipse parser.
    // "d" is 2 for normal and 3 for reversed.
    var d = 2;
    typeLoop:
    while (reader.hasNext()) {
      switch (reader.selectName(_names)) {
        case 0:
          type = reader.nextString();
          break typeLoop;
        case 1:
          d = reader.nextInt();
        default:
          reader.skipName();
          reader.skipValue();
      }
    }

    if (type == null) {
      return null;
    }

    ContentModel? model;
    switch (type) {
      case 'gr':
        model = ShapeGroupParser.parse(reader, composition);
      case 'st':
        model = ShapeStrokeParser.parse(reader, composition);
      case 'gs':
        model = GradientStrokeParser.parse(reader, composition);
      case 'fl':
        model = ShapeFillParser.parse(reader, composition);
      case 'gf':
        model = GradientFillParser.parse(reader, composition);
      case 'tr':
        model = AnimatableTransformParser.parse(reader, composition);
      case 'sh':
        model = ShapePathParser.parse(reader, composition);
      case 'el':
        model = CircleShapeParser.parse(reader, composition, d);
      case 'rc':
        model = RectangleShapeParser.parse(reader, composition);
      case 'tm':
        model = ShapeTrimPathParser.parse(reader, composition);
      case 'sr':
        model = PolystarShapeParser.parse(reader, composition, d: d);
      case 'mm':
        model = MergePathsParser.parse(reader);
      case 'rp':
        model = RepeaterParser.parse(reader, composition);
      case 'rd':
        model = RoundedCornersParser.parse(reader, composition);
      default:
        composition.addWarning('Unknown shape type $type');
    }

    while (reader.hasNext()) {
      reader.skipValue();
    }
    reader.endObject();

    return model;
  }
}
