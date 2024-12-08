import 'dart:convert';
import 'dart:io';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

final RegExp _importRegex = RegExp(r"import '([^']+)';\r?\n");

final DartFormatter _dartFormatter = DartFormatter(
    languageVersion: Version(3, 5, 0),
    lineEnding: Platform.isWindows ? '\r\n' : '\n');

void main() {
  File('README.md')
      .writeAsStringSync(generateReadme(File('README.template.md')));
  File('example/README.md')
      .writeAsStringSync(generateReadme(File('example/README.template.md')));
}

String generateReadme(File source) {
  var template = source.readAsStringSync();

  var readme = template.replaceAllMapped(_importRegex, (match) {
    var filePath = match.group(1)!;

    var splitPath = filePath.split('#');

    var actualPath = splitPath.first;
    actualPath = p.join(p.dirname(source.path), actualPath);

    var fileContent = File(actualPath).readAsStringSync();
    if (splitPath.length > 1) {
      var sectionName = splitPath[1];

      fileContent = _extractSection(fileContent, sectionName.trim());
    }

    fileContent = _dartFormatter.format(fileContent);

    return fileContent;
  });

  return readme;
}

String _extractSection(String content, String sectionName) {
  var lines = LineSplitter.split(content);
  bool isBlockStarter(String line, String section) =>
      line.trim().startsWith(RegExp(r'\/\/\s*-{2,}\s*' '$section'));
  lines = lines
      .skipWhile((l) => !isBlockStarter(l, sectionName))
      .skip(1)
      .takeWhile((l) => !isBlockStarter(l, ''))
      .toList();

  return lines.join('\n');
}
