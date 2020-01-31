import '../../animation/content/content.dart';
import '../../animation/content/merge_paths_content.dart';
import '../../lottie_drawable.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

enum MergePathsMode { MERGE, ADD, SUBTRACT, INTERSECT, EXCLUDE_INTERSECTIONS }

class MergePaths implements ContentModel {
  final String name;
  final MergePathsMode mode;
  final bool hidden;

  MergePaths({this.name, this.mode, this.hidden});

  @override
  Content /*?*/ toContent(LottieDrawable drawable, BaseLayer layer) {
    return MergePathsContent(this);
  }

  @override
  String toString() {
    return 'MergePaths{mode=$mode}';
  }

  static MergePathsMode modeForId(int id) {
    switch (id) {
      case 1:
        return MergePathsMode.MERGE;
      case 2:
        return MergePathsMode.ADD;
      case 3:
        return MergePathsMode.SUBTRACT;
      case 4:
        return MergePathsMode.INTERSECT;
      case 5:
        return MergePathsMode.EXCLUDE_INTERSECTIONS;
      default:
        return MergePathsMode.MERGE;
    }
  }
}
