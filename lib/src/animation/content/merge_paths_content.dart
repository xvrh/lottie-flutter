import 'dart:ui';
import '../../model/content/merge_paths.dart';
import '../../utils.dart';
import 'content.dart';
import 'content_group.dart';
import 'greedy_content.dart';
import 'path_content.dart';

class MergePathsContent implements PathContent, GreedyContent {
  final Path _firstPath = Path();
  final Path _remainderPath = Path();
  final Path _path = Path();

  final List<PathContent> _pathContents = <PathContent>[];
  final MergePaths _mergePaths;

  MergePathsContent(this._mergePaths);

  @override
  void absorbContent(List<Content> contents) {
    // Fast forward the iterator until after this content.
    var index = contents.lastIndexOf(this) - 1;

    while (index >= 0) {
      var content = contents[index];
      if (content is PathContent) {
        _pathContents.add(content);
        contents.removeAt(index);
      }
      --index;
    }
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    for (var i = 0; i < _pathContents.length; i++) {
      _pathContents[i].setContents(contentsBefore, contentsAfter);
    }
  }

  @override
  Path getPath() {
    _path.reset();

    if (_mergePaths.hidden) {
      return _path;
    }

    switch (_mergePaths.mode) {
      case MergePathsMode.merge:
        _addPaths();
      case MergePathsMode.add:
        _opFirstPathWithRest(PathOperation.union);
      case MergePathsMode.substract:
        _opFirstPathWithRest(PathOperation.reverseDifference);
      case MergePathsMode.intersect:
        _opFirstPathWithRest(PathOperation.intersect);
      case MergePathsMode.excludeIntersections:
        _opFirstPathWithRest(PathOperation.xor);
    }

    return _path;
  }

  @override
  String get name => _mergePaths.name;

  void _addPaths() {
    for (var i = 0; i < _pathContents.length; i++) {
      _path.addPath(_pathContents[i].getPath(), Offset.zero);
    }
  }

  void _opFirstPathWithRest(PathOperation op) {
    _remainderPath.reset();
    _firstPath.reset();

    for (var i = _pathContents.length - 1; i >= 1; i--) {
      var content = _pathContents[i];

      if (content is ContentGroup) {
        var pathList = content.getPathList();
        for (var j = pathList.length - 1; j >= 0; j--) {
          var path = pathList[j].getPath();
          path = path.transform(content.getTransformationMatrix().storage);
          _remainderPath.addPath(path, Offset.zero);
        }
      } else {
        _remainderPath.addPath(content.getPath(), Offset.zero);
      }
    }

    var lastContent = _pathContents[0];
    if (lastContent is ContentGroup) {
      var pathList = lastContent.getPathList();
      for (var j = 0; j < pathList.length; j++) {
        var path = pathList[j].getPath();
        path = path.transform(lastContent.getTransformationMatrix().storage);
        _firstPath.addPath(path, Offset.zero);
      }
    } else {
      _firstPath.set(lastContent.getPath());
    }

    _path.set(Path.combine(op, _firstPath, _remainderPath));
  }
}
