import 'dart:convert';
import 'dart:io';

void main() {
  var pubspec = File('pubspec.yaml');
  var content = pubspec.readAsStringSync();

  var overrides = '''
dependency_overrides:
  pedantic: ^1.9.0''';

  content = content.replaceAll(
      overrides, LineSplitter.split(overrides).map((l) => '#$l').join('\n'));

  pubspec.writeAsStringSync(content);
}
