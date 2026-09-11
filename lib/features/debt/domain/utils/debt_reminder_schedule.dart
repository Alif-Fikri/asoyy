const debtReminderIntervalDays = 3;

/// Computes the next reminder check-in time for an unpaid debt/participant.
///
/// Reminders start [debtReminderIntervalDays] after [since] and repeat every
/// [debtReminderIntervalDays] while still unpaid, evaluated relative to [now].
DateTime nextDebtReminderTime(DateTime since, DateTime now) {
  var next = since.add(const Duration(days: debtReminderIntervalDays));
  while (!next.isAfter(now)) {
    next = next.add(const Duration(days: debtReminderIntervalDays));
  }
  return next;
}

int daysSince(DateTime since, DateTime now) => now.difference(since).inDays;
