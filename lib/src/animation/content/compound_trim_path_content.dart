import 'dart:ui';
import '../../utils/utils.dart';
import 'trim_path_content.dart';

class CompoundTrimPathContent {
  final List<TrimPathContent> _contents = <TrimPathContent>[];

  void addTrimPath(TrimPathContent trimPath) {
    _contents.add(trimPath);
  }

  void apply(Path path) {
    for (var i = _contents.length - 1; i >= 0; i--) {
      Utils.applyTrimPathContentIfNeeded(path, _contents[i]);
    }
  }
}
