import 'package:logging/logging.dart';
import 'package:lottie/src/expression/interpreter/interpreter.dart';
import 'arguments.dart';
import 'context.dart';
import 'function.dart';
import 'object.dart';
import 'interpreter.dart';

class JsConsole extends JsObject {
  final Map<String, int> _counts = {};
  final Map<String, Stopwatch> _time = <String, Stopwatch>{};
  final Logger _logger;

  JsConsole(this._logger) {
    void _func(String name,
        JsObject Function(Interpreter, JsArguments, InterpreterContext) f) {
      properties[name] = JsFunction(this, f)..name = name;
    }

    _func('assert', _assert);
    _func('clear', _fake('clear'));
    _func('count', count);
    _func('dir', dir);
    _func('dirxml', dirxml);
    _func('error', error);
    _func('group', _fake('group'));
    _func('groupCollapsed', _fake('groupCollapsed'));
    _func('groupEnd', _fake('groupEnd'));
    _func('info', info);
    _func('log', info);
    _func('table', table);
    _func('time', time);
    _func('timeEnd', timeEnd);
    _func('trace', trace);
    _func('warn', warn);
  }

  JsObject _assert(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    var condition = arguments.getProperty(0.0, interpreter, ctx);

    if (condition?.isTruthy == true) {
      _logger.info(arguments.valueOf.skip(1).join(' '));
    }

    return null;
  }

  JsObject Function(Interpreter, JsArguments, InterpreterContext ctx) _fake(
      String name) {
    return (Interpreter interpreter, JsArguments arguments,
        InterpreterContext ctx) {
      _logger.fine('`console.$name` was called.');
      return null;
    };
  }

  JsObject count(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    var label = arguments.getProperty(0.0, interpreter, ctx)?.toString() ??
        '<no label>';
    _counts.putIfAbsent(label, () => 1);
    var v = _counts[label]++;
    _logger.info('$label: $v');

    return null;
  }

  JsObject dir(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    var obj = arguments.getProperty(0.0, interpreter, ctx);

    if (obj != null) {
      _logger.info(obj.properties);
    }

    return null;
  }

  JsObject dirxml(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    var obj = arguments.getProperty(0.0, interpreter, ctx);

    if (obj != null) {
      _logger.info('XML: $obj');
    }

    return null;
  }

  JsObject error(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    _logger.severe(arguments.valueOf.join(' '));
    return null;
  }

  JsObject info(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    _logger.info(arguments.valueOf.join(' '));
    return null;
  }

  JsObject warn(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    _logger.warning(arguments.valueOf.join(' '));
    return null;
  }

  JsObject table(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    // TODO: Is there a need to actually make this a table?
    _logger.info(arguments.valueOf.join(' '));
    return null;
  }

  JsObject time(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    var label = arguments.getProperty(0.0, interpreter, ctx)?.toString();

    if (label != null) {
      _time.putIfAbsent(label, () => Stopwatch()..start());
    }
    return null;
  }

  JsObject timeEnd(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    var label = arguments.getProperty(0.0, interpreter, ctx)?.toString();

    if (label != null) {
      var sw = _time.remove(label);

      if (sw != null) {
        sw.stop();
        _logger.info('$label: ${sw.elapsedMicroseconds / 1000}ms');
      }
    }

    return null;
  }

  JsObject trace(
      Interpreter interpreter, JsArguments arguments, InterpreterContext ctx) {
    for (var frame in ctx.callStack.frames) {
      _logger.info(frame);
    }

    return null;
  }
}
