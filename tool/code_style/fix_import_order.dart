import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';
import 'dart_project.dart';

// ignore_for_file: avoid_print

void main() {
  for (var project in getSubOrContainingProjects(Directory.current.path)) {
    for (var dartFile in project.getDartFiles()) {
      try {
        fixFile(dartFile);
      } catch (e, s) {
        print('Error while fixing ${dartFile.path}\n$e\n$s');
        rethrow;
      }
    }
  }
}

bool fixFile(DartFile dartFile) {
  var content = dartFile.file.readAsStringSync();

  var newContent = reorderImports(content);

  if (content != newContent) {
    dartFile.file.writeAsStringSync(newContent);
    return true;
  }
  return false;
}

final DartFormatter _dartFormatter =
    DartFormatter(languageVersion: Version(3, 5, 0));

final String newLineChar = Platform.isWindows ? '\r\n' : '\n';

String reorderImports(String source) {
  return _reorderImports(source, parseString(content: source).unit);
}

String _reorderImports(String content, CompilationUnit unit) {
  var wholeDirectives = <_WholeDirective>[];
  var imports = <ImportDirective>[];
  var exports = <ExportDirective>[];
  var parts = <PartDirective>[];

  var minOffset = 0, maxOffset = 0;
  var lastOffset = 0;
  var isFirst = true;
  for (var directive in unit.directives) {
    if (directive is UriBasedDirective) {
      int offset, length;
      if (isFirst) {
        isFirst = false;

        var token = directive.metadata.beginToken ??
            directive.firstTokenAfterCommentAndMetadata;

        offset = token.offset;
        length =
            (directive.endToken.offset + directive.endToken.length) - offset;
        minOffset = offset;
        maxOffset = length + offset;
      } else {
        offset = lastOffset;
        length =
            directive.endToken.offset + directive.endToken.length - lastOffset;
      }

      maxOffset = offset + length;
      lastOffset = maxOffset;

      var wholeDirective = _WholeDirective(directive, offset, length);
      wholeDirectives.add(wholeDirective);

      if (directive is ImportDirective) {
        imports.add(directive);
      } else if (directive is ExportDirective) {
        exports.add(directive);
      } else {
        parts.add(directive as PartDirective);
      }
    }
  }

  imports.sort(_compare);
  exports.sort(_compare);
  parts.sort(_compare);

  var contentBefore = content.substring(0, minOffset);
  var reorderedContent = '';

  String writeBlock(List<UriBasedDirective> directives) {
    var result = '';
    for (var directive in directives) {
      var wholeDirective = wholeDirectives.firstWhere(
          (wholeDirective) => wholeDirective.directive == directive);
      var directiveString = content.substring(wholeDirective.countedOffset,
          wholeDirective.countedOffset + wholeDirective.countedLength);

      var normalizedDirective = directive.toString().replaceAll('"', "'");
      directiveString =
          directiveString.replaceAll(directive.toString(), normalizedDirective);

      result += directiveString;
    }
    return '$result$newLineChar$newLineChar';
  }

  reorderedContent += _removeBlankLines(writeBlock(imports));
  reorderedContent += _removeBlankLines(writeBlock(exports));
  reorderedContent += _removeBlankLines(writeBlock(parts));

  var contentAfter = content.substring(maxOffset);

  var newContent = contentBefore + reorderedContent + contentAfter;

  newContent = _dartFormatter.format(newContent);

  return newContent;
}

String _removeBlankLines(String content) {
  var lines = LineSplitter.split(content).toList();
  var result = <String>[];
  var i = 0;
  for (var line in lines) {
    if (i == 0 || line.trim().isNotEmpty) {
      result.add(line);
    }
    ++i;
  }

  return newLineChar + result.join(newLineChar);
}

int _compare(UriBasedDirective directive1, UriBasedDirective directive2) {
  var uri1 = directive1.uri.stringValue!;
  var uri2 = directive2.uri.stringValue!;

  if (uri1.contains(':') && !uri2.contains(':')) {
    return -1;
  } else if (!uri1.contains(':') && uri2.contains(':')) {
    return 1;
  } else {
    return uri1.compareTo(uri2);
  }
}

class _WholeDirective {
  final UriBasedDirective directive;
  final int countedOffset;
  final int countedLength;

  _WholeDirective(this.directive, this.countedOffset, this.countedLength);
}
