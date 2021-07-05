import '../../animation/content/content.dart';
import '../../animation/content/merge_paths_content.dart';
import '../../lottie_drawable.dart';
import '../layer/base_layer.dart';
import 'content_model.dart';

enum MergePathsMode { merge, add, substract, intersect, excludeIntersections }

class MergePaths implements ContentModel {
  final String name;
  final MergePathsMode mode;
  final bool hidden;

  MergePaths({required this.name, required this.mode, required this.hidden});

  @override
  Content? toContent(LottieDrawable drawable, BaseLayer layer) {
    if (!drawable.enableMergePaths) {
      drawable.composition
          .addWarning('Animation contains merge paths but they are disabled.');
      return null;
    }
    return MergePathsContent(this);
  }

  @override
  String toString() {
    return 'MergePaths{mode=$mode}';
  }

  static MergePathsMode modeForId(int id) {
    switch (id) {
      case 1:
        return MergePathsMode.merge;
      case 2:
        return MergePathsMode.add;
      case 3:
        return MergePathsMode.substract;
      case 4:
        return MergePathsMode.intersect;
      case 5:
        return MergePathsMode.excludeIntersections;
      default:
        return MergePathsMode.merge;
    }
  }
}
