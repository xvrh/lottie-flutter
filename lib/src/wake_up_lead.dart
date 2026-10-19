/// How long before a change an animation that stopped ticking has to tick
/// again.
///
/// A device may slow down while no frame is produced (the display lowers its
/// refresh rate, the CPU and the GPU their frequency) and deliver the first
/// frames after the wait late. The ticks of the lead draw nothing new, they
/// are there to absorb that delay.
///
/// The lead is at least [minimum]. It is made longer for a device that is
/// measured to need more: after each wait, the time it takes for the ticks to
/// come at the regular interval again. The measure never makes it shorter: a
/// lead that is too long costs a few frames that draw nothing, one that is too
/// short loses the first frames of a movement.
class WakeUpLead {
  static const minimum = Duration(milliseconds: 200);
  static const _max = Duration(milliseconds: 500);

  /// A tick is late when it comes after this many intervals. A device that is
  /// not fast enough for the animation ticks every other interval, which is
  /// its regular cadence, not a delay.
  static const _lateAfterIntervals = 2.5;

  /// The ticks that have to come on time in a row for the device to be
  /// considered back to its regular cadence. The first ticks after a wait can
  /// be on time and the delay come after them, while the first frames are
  /// still being rasterized.
  static const _onTimeTicks = 4;

  /// The ticks at the regular interval kept between the delay and the change.
  static const _marginIntervals = 3;

  /// The lead covers the slowest of this many last wake-ups: the delay varies
  /// from one wake-up to the next.
  static const _measureCount = 6;

  Duration get value => _value;
  Duration _value = minimum;

  final _delays = <Duration>[];

  /// When the wait being measured was due to end, if a measure is in progress.
  Duration? _wakeUpDue;
  Duration _previousTick = Duration.zero;
  Duration _lastLateTick = Duration.zero;
  int _onTime = 0;

  /// Records a tick at [elapsed]. [interval] is the time between two ticks
  /// when nothing is late. [wakeUpDue] is given for the tick that ends a wait:
  /// the time at which this tick was due.
  void tick(
    Duration elapsed, {
    required Duration interval,
    Duration? wakeUpDue,
  }) {
    var lateAfter = interval * _lateAfterIntervals;
    if (wakeUpDue != null) {
      // The delay is counted from the time the tick was due: this tick can be
      // late too.
      _wakeUpDue = wakeUpDue;
      _lastLateTick = elapsed - wakeUpDue > lateAfter ? elapsed : wakeUpDue;
      _previousTick = elapsed;
      _onTime = 0;
      return;
    }
    var due = _wakeUpDue;
    if (due == null) return;

    var isLate = elapsed - _previousTick > lateAfter;
    _previousTick = elapsed;
    if (isLate) {
      _lastLateTick = elapsed;
      _onTime = 0;
    } else if (++_onTime == _onTimeTicks) {
      _wakeUpDue = null;
      _delays.add(_lastLateTick - due);
      if (_delays.length > _measureCount) {
        _delays.removeAt(0);
      }
      var slowest = _delays.reduce((a, b) => a > b ? a : b);
      var lead = slowest + interval * _marginIntervals;
      _value = lead < minimum ? minimum : (lead < _max ? lead : _max);
    }
  }

  /// Drops the measure in progress, when the ticks start over.
  void cancelMeasure() {
    _wakeUpDue = null;
  }
}
