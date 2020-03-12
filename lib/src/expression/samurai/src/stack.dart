import 'dart:collection';

class CallStack {
  final Queue<Frame> _frames = new Queue<Frame>();

  List<Frame> get frames => _frames.toList();

  void clear() => _frames.clear();

  void push(String filename, int line, String name) {
    _frames.addFirst(new Frame(filename, line, name));
  }

  void pop() {
    if (_frames.isNotEmpty) _frames.removeFirst();
  }

  SamuraiException error(String type, String message) {
    var msg = '${type}Error: $message';
    var frames = _frames.toList();
    return new SamuraiException(msg, frames);
  }

  CallStack duplicate() {
    return new CallStack().._frames.addAll(_frames);
  }
}

class Frame {
  final String filename;
  final int line;
  final String name;

  Frame(this.filename, this.line, this.name);

  @override
  String toString() =>
      filename == null ? '$name:$line' : '$name:$filename:$line';
}

class SamuraiException implements Exception {
  final String message;
  final List<Frame> stackTrace;

  SamuraiException(this.message, this.stackTrace);

  @override
  String toString() {
    var b = new StringBuffer('$message');

    if (stackTrace.isNotEmpty) {
      b.writeln();
      b.writeln();
      stackTrace.forEach(b.writeln);
    }

    return b.toString();
  }
}
