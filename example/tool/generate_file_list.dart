import 'dart:io';

void main() {
  var buffer = StringBuffer();
  buffer.writeln('// Generated from tool/generate_file_list.dart');
  buffer.writeln('final files = [');
  for (var file in Directory('assets')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json') || f.path.endsWith('.zip'))) {
    buffer.writeln("  '${file.path}',");
  }
  buffer.writeln('];');
  File('lib/src/all_files.g.dart').writeAsStringSync('$buffer');
}
