import 'dart:ui';
import '../../utils/utils.dart';
import 'trim_path_content.dart';

class CompoundTrimPathContent {
  final List<TrimPathContent> _contents = <TrimPathContent>[];

  void addTrimPath(TrimPathContent trimPath) {
    _contents.add(trimPath);
  }

  /// Last path returned by [apply]. Used so cached `getPath` calls keep the
  /// trimmed result instead of the untrimmed source.
  Path? applied;

  Path apply(Path path) {
    var result = path;
    for (var i = _contents.length - 1; i >= 0; i--) {
      result = Utils.applyTrimPathContentIfNeeded(result, _contents[i]);
    }
    applied = result;
    return result;
  }
}
