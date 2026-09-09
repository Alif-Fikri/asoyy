import '../entities/recurring_transaction_entity.dart';

DateTime nextDueDate(RecurringTransactionEntity item, DateTime now) {
  final currentMonthKey =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';
  DateTime dueDate;
  if (item.lastGeneratedMonth == currentMonthKey) {
    dueDate = DateTime(now.year, now.month + 1, item.dayOfMonth);
  } else {
    dueDate = DateTime(now.year, now.month, item.dayOfMonth);
    if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
      dueDate = DateTime(now.year, now.month + 1, item.dayOfMonth);
    }
  }
  return dueDate;
}

DateTime nextReminderTime(RecurringTransactionEntity item, DateTime now) {
  final due = nextDueDate(item, now);
  return DateTime(due.year, due.month, due.day - 1, 9);
}
