const debtReminderIntervalDays = 3;

DateTime nextDebtReminderTime(DateTime since, DateTime now) {
  var next = since.add(const Duration(days: debtReminderIntervalDays));
  while (!next.isAfter(now)) {
    next = next.add(const Duration(days: debtReminderIntervalDays));
  }
  return next;
}

int daysSince(DateTime since, DateTime now) => now.difference(since).inDays;
