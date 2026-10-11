import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/src/wake_up_lead.dart';

const interval = Duration(microseconds: 16667);
const late = Duration(milliseconds: 300);

/// The ticks at the regular interval kept between a delay and the change.
final margin = interval * 3;

/// Ticks [lead] once after a wait, [wakeUpLate] after the tick was due, then
/// at each of the [gaps] from the previous tick.
void wakeUp(
  WakeUpLead lead,
  List<Duration> gaps, {
  Duration wakeUpLate = Duration.zero,
}) {
  const due = Duration(seconds: 1);
  var elapsed = due + wakeUpLate;
  lead.tick(elapsed, interval: interval, wakeUpDue: due);
  for (var gap in gaps) {
    elapsed += gap;
    lead.tick(elapsed, interval: interval);
  }
}

void main() {
  test('is the minimum before the first wait', () {
    var lead = WakeUpLead();
    for (var i = 0; i < 10; i++) {
      lead.tick(interval * i, interval: interval);
    }
    expect(lead.value, WakeUpLead.minimum);
  });

  test('is not made shorter by ticks that are on time after a wait', () {
    var lead = WakeUpLead();

    for (var i = 0; i < 10; i++) {
      wakeUp(lead, [interval, interval, interval, interval]);
    }
    expect(lead.value, WakeUpLead.minimum);
  });

  test('is not made shorter by a short delay', () {
    var lead = WakeUpLead();
    const short = Duration(milliseconds: 60);

    wakeUp(lead, [short, interval, interval, interval, interval]);
    expect(lead.value, WakeUpLead.minimum);
  });

  test('a device ticking every other interval is not late', () {
    var lead = WakeUpLead();
    var slowCadence = interval * 2;

    wakeUp(lead, [late, slowCadence, slowCadence, slowCadence, slowCadence]);
    expect(lead.value, late + margin);
  });

  test('covers the ticks that come late after a wait', () {
    var lead = WakeUpLead();
    const slow = Duration(milliseconds: 50);

    // The delay is over at the last late tick.
    wakeUp(lead, [late, slow, interval, interval, interval, interval]);
    expect(lead.value, late + slow + margin);
  });

  test('covers a delay that comes after ticks on time', () {
    var lead = WakeUpLead();

    wakeUp(lead, [interval, interval, late, interval, interval, interval]);
    expect(lead.value, WakeUpLead.minimum);

    wakeUp(lead, [
      interval,
      interval,
      late,
      interval,
      interval,
      interval,
      interval,
    ]);
    expect(lead.value, interval * 2 + late + margin);
  });

  test('counts the delay from the time the first tick was due', () {
    var lead = WakeUpLead();
    const wakeUpLate = Duration(milliseconds: 30);

    wakeUp(lead, [
      late,
      interval,
      interval,
      interval,
      interval,
    ], wakeUpLate: wakeUpLate);
    expect(lead.value, wakeUpLate + late + margin);
  });

  test('covers a first tick that is late', () {
    var lead = WakeUpLead();

    wakeUp(lead, [interval, interval, interval, interval], wakeUpLate: late);
    expect(lead.value, late + margin);
  });

  test('covers the slowest of the last wake-ups', () {
    var lead = WakeUpLead();

    wakeUp(lead, [late, interval, interval, interval, interval]);
    for (var i = 0; i < 5; i++) {
      wakeUp(lead, [interval, interval, interval, interval]);
      expect(lead.value, late + margin);
    }

    wakeUp(lead, [interval, interval, interval, interval]);
    expect(lead.value, WakeUpLead.minimum);
  });

  test('is capped', () {
    var lead = WakeUpLead();

    wakeUp(lead, [
      const Duration(seconds: 3),
      interval,
      interval,
      interval,
      interval,
    ]);
    expect(lead.value, const Duration(milliseconds: 500));
  });

  test('a cancelled measure is dropped', () {
    var lead = WakeUpLead();

    wakeUp(lead, [late, interval]);
    lead.cancelMeasure();
    for (var i = 1; i <= 8; i++) {
      lead.tick(interval * i, interval: interval);
    }
    expect(lead.value, WakeUpLead.minimum);
  });
}
