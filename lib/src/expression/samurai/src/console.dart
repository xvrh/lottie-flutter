import 'package:logging/logging.dart';
import '../../symbol_table/symbol_table.dart';
import 'arguments.dart';
import 'context.dart';
import 'function.dart';
import 'object.dart';
import 'samurai.dart';

class JsConsole extends JsObject {
  final Map<String, int> _counts = {};
  final Map<String, Stopwatch> _time = <String, Stopwatch>{};
  Logger _logger;

  JsConsole(this._logger) {
    _func(String name,
        JsObject Function(Samurai, JsArguments, SamuraiContext) f) {
      properties[name] = new JsFunction(this, f)..name = name;
    }

    _func('assert', assert_);
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

  JsObject assert_(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    var condition = arguments.getProperty(0.0, samurai, ctx);

    if (condition?.isTruthy == true) {
      _logger.info(arguments.valueOf.skip(1).join(' '));
    }

    return null;
  }

  JsObject Function(Samurai, JsArguments, SamuraiContext ctx) _fake(
      String name) {
    return (Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
      _logger.fine('`console.$name` was called.');
      return null;
    };
  }

  JsObject count(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    var label =
        arguments.getProperty(0.0, samurai, ctx)?.toString() ?? '<no label>';
    _counts.putIfAbsent(label, () => 1);
    var v = _counts[label]++;
    _logger.info('$label: $v');

    return null;
  }

  JsObject dir(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    var obj = arguments.getProperty(0.0, samurai, ctx);

    if (obj != null) {
      _logger.info(obj.properties);
    }

    return null;
  }

  JsObject dirxml(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    var obj = arguments.getProperty(0.0, samurai, ctx);

    if (obj != null) {
      _logger.info('XML: $obj');
    }

    return null;
  }

  JsObject error(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    _logger.severe(arguments.valueOf.join(' '));
    return null;
  }

  JsObject info(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    _logger.info(arguments.valueOf.join(' '));
    return null;
  }

  JsObject warn(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    _logger.warning(arguments.valueOf.join(' '));
    return null;
  }

  JsObject table(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    // TODO: Is there a need to actually make this a table?
    _logger.info(arguments.valueOf.join(' '));
    return null;
  }

  JsObject time(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    var label = arguments.getProperty(0.0, samurai, ctx)?.toString();

    if (label != null) {
      _time.putIfAbsent(label, () => new Stopwatch()..start());
    }
    return null;
  }

  JsObject timeEnd(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    var label = arguments.getProperty(0.0, samurai, ctx)?.toString();

    if (label != null) {
      var sw = _time.remove(label);

      if (sw != null) {
        sw.stop();
        _logger.info('$label: ${sw.elapsedMicroseconds / 1000}ms');
      }
    }

    return null;
  }

  JsObject trace(Samurai samurai, JsArguments arguments, SamuraiContext ctx) {
    for (var frame in ctx.callStack.frames) {
      _logger.info(frame);
    }

    return null;
  }
}
