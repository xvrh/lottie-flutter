import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'pubspec_helper.dart';

List<DartProject> getDartProjects(String root) {
  var paths = <DartProject>[];

  for (var file in findPubspecs(Directory(root))) {
    var relativePath = p.relative(file.path, from: root);
    if (p
        .split(relativePath)
        .any((part) => part.startsWith('_') || part.startsWith('.'))) {
      continue;
    }

    paths.add(DartProject(p.normalize(file.parent.absolute.path)));
  }

  return paths;
}

DartProject? getContainingProject(String currentPath) {
  var dir = Directory(currentPath);

  while (true) {
    if (dir.listSync(followLinks: false).any((r) =>
        r is File && p.basename(r.path).toLowerCase() == 'pubspec.yaml')) {
      return DartProject(dir.path, listingPath: currentPath);
    }
    var parent = dir.parent;
    if (dir.path == parent.path) {
      return null;
    }

    dir = parent;
  }
}

/// Retourne les sous-projets ou le projet qui contient le dossier cible.
List<DartProject> getSubOrContainingProjects(String root) {
  var projects = getDartProjects(root);
  if (projects.isEmpty) {
    var containingProject = getContainingProject(root);
    return [if (containingProject != null) containingProject];
  } else {
    return projects;
  }
}

bool isInHiddenDir(String relative) =>
    p.split(relative).any((part) => part.startsWith('.') || part == 'build');

class DartProject {
  final String rootDirectory;
  final String _listingPath;
  final String _packageName;

  DartProject(this.rootDirectory, {String? listingPath})
      : _packageName = _getPackageName(rootDirectory),
        _listingPath = listingPath ?? rootDirectory;

  String get packageName => _packageName;

  String get absoluteRootDirectory => Directory(rootDirectory).absolute.path;

  static String _getPackageName(String projectRoot) {
    var pubspecContent =
        File(p.join(projectRoot, 'pubspec.yaml')).readAsStringSync();
    var loadedPubspec = loadYaml(pubspecContent) as YamlMap;

    return loadedPubspec['name'] as String;
  }

  List<DartFile> getDartFiles() {
    var files = <DartFile>[];
    _visitDirectory(Directory(_listingPath), files, isRoot: true);
    return files;
  }

  void _visitDirectory(Directory directory, List<DartFile> files,
      {required bool isRoot}) {
    var directoryContent = directory.listSync();

    // On ne visite pas les sous dossiers qui contiennent un autre package
    if (!isRoot &&
        directoryContent
            .any((f) => f is File && f.path.endsWith('pubspec.yaml'))) {
      return;
    }

    for (var entity in directoryContent) {
      if (entity is File && entity.path.endsWith('.dart')) {
        var absoluteFile = entity.absolute;
        var absolute = absoluteFile.path;

        if (!isInHiddenDir(p.relative(absolute, from: rootDirectory))) {
          files.add(DartFile(this, absoluteFile));
        }
      } else if (entity is Directory) {
        _visitDirectory(entity, files, isRoot: false);
      }
    }
  }
}

class DartFile {
  final DartProject project;
  final File file;
  final String _relativePath;

  DartFile(this.project, this.file)
      : _relativePath =
            p.relative(file.absolute.path, from: project.rootDirectory);

  String get path => file.path;

  String get relativePath => _relativePath;

  String get normalizedRelativePath => relativePath.replaceAll(r'\', '/');

  @override
  String toString() => 'DartFile($file)';
}
