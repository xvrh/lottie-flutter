import 'dart:ui';
import '../../utils/utils.dart';
import 'trim_path_content.dart';

class CompoundTrimPathContent {
  final List<TrimPathContent> _contents = <TrimPathContent>[];

  void addTrimPath(TrimPathContent trimPath) {
    _contents.add(trimPath);
  }

  Path apply(Path path) {
    var result = path;
    for (var i = _contents.length - 1; i >= 0; i--) {
      result = Utils.applyTrimPathContentIfNeeded(result, _contents[i]);
    }
    return result;
  }
}
