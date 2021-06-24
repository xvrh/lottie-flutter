import 'dart:io';
import 'package:path/path.dart' as p;

List<File> findPubspecs(Directory root, {bool pubspecLock = false}) {
  return findPackages(root, 'pubspec${pubspecLock ? '.lock' : '.yaml'}');
}

List<File> findPackages(Directory root, String fileName) {
  return _findPubspecs(root, fileName);
}

List<File> _findPubspecs(Directory root, String file) {
  var results = <File>[];
  var entities = root.listSync();
  var hasPubspec = false;
  for (var entity in entities.whereType<File>()) {
    if (p.basename(entity.path) == file) {
      hasPubspec = true;
      results.add(entity);
    }
  }

  for (var dir in entities.whereType<Directory>()) {
    var dirName = p.basename(dir.path);

    if (!dirName.startsWith('.') &&
        !dirName.startsWith('_') &&
        (!hasPubspec || !const ['web', 'lib', 'test'].contains(dirName))) {
      results.addAll(_findPubspecs(dir, file));
    }
  }
  return results;
}
