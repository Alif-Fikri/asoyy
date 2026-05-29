class HijriDate {
  final int year;
  final int month;
  final int day;

  const HijriDate(this.year, this.month, this.day);

  static const _monthNames = [
    'Muharram', 'Safar', "Rabi'ul Awal", "Rabi'ul Akhir",
    'Jumadil Awal', 'Jumadil Akhir', 'Rajab', "Sya'ban",
    'Ramadhan', 'Syawal', 'Dzulqaidah', 'Dzulhijjah',
  ];

  String get monthName => _monthNames[month - 1];
  String toFullString() => '$day ${_monthNames[month - 1]} $year H';

  static HijriDate fromGregorian(DateTime date) {
    int a = (14 - date.month) ~/ 12;
    int y = date.year + 4800 - a;
    int m = date.month + 12 * a - 3;
    int jdn = date.day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;

    int daysSinceEpoch = jdn - 1948439;

    int cycles = daysSinceEpoch ~/ 10631;
    int remaining = daysSinceEpoch % 10631;

    int yearInCycle = 1;
    while (yearInCycle <= 30) {
      int diy = _isLeap(cycles * 30 + yearInCycle) ? 355 : 354;
      if (remaining < diy) break;
      remaining -= diy;
      yearInCycle++;
    }
    int hYear = cycles * 30 + yearInCycle;

    int hMonth = 1;
    while (hMonth <= 12) {
      int dim = _daysInMonth(hMonth, hYear);
      if (remaining < dim) break;
      remaining -= dim;
      hMonth++;
    }

    return HijriDate(hYear, hMonth, remaining + 1);
  }

  static bool _isLeap(int year) => (11 * year + 14) % 30 < 11;

  static int _daysInMonth(int month, int year) {
    if (month % 2 == 1) return 30;
    if (month == 12 && _isLeap(year)) return 30;
    return 29;
  }
}
