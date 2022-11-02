import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'dart_project.dart';

// ignore_for_file: avoid_print

// A script that replace all absolute imports to relative one
// import 'package:slot/src/my_slot.dart' => 'import '../my_slot.dart';
void main() {
  var root = Directory.current.path;

  for (var project in getSubOrContainingProjects(root)) {
    for (var dartFile in project.getDartFiles().where(
        (dartFile) => dartFile.normalizedRelativePath.startsWith('lib/'))) {
      fixFile(dartFile);
    }
  }
}

bool fixFile(DartFile dartFile) {
  var content = dartFile.file.readAsStringSync();
  var newContent = fixCode(dartFile, content);

  if (content != newContent) {
    dartFile.file.writeAsStringSync(newContent);
    return true;
  }
  return false;
}

String fixCode(DartFile dartFile, String content) {
  try {
    var newContent = content;

    var unit = parseString(content: content).unit;

    for (var directive
        in unit.directives.reversed.whereType<NamespaceDirective>()) {
      var uriValue = directive.uri.stringValue!;
      var absolutePrefix = 'package:${dartFile.project.packageName}/';
      if (uriValue.startsWith(absolutePrefix)) {
        var absoluteImportFromLib = uriValue.replaceAll(absolutePrefix, '');
        var thisFilePath = dartFile.relativePath.substring('lib/'.length);
        var relativePath = p
            .relative(absoluteImportFromLib, from: p.dirname(thisFilePath))
            .replaceAll(r'\', '/');

        var directiveContent =
            directive.uri.toString().replaceAll(uriValue, relativePath);

        newContent = newContent.replaceRange(directive.uri.offset,
            directive.uri.offset + directive.uri.length, directiveContent);
      }
    }

    return newContent;
  } catch (e) {
    print(
        'Error while parsing file package:${dartFile.project.packageName}/${dartFile.relativePath}');
    rethrow;
  }
}
