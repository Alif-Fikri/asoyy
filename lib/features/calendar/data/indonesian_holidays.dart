import '../domain/entities/holiday_entity.dart';

abstract class IndonesianHolidays {
  static final List<HolidayEntity> all = [..._holidays2025, ..._holidays2026];

  static final _holidays2025 = <HolidayEntity>[

    HolidayEntity(date: DateTime(2025, 1, 1), nameId: 'Tahun Baru Masehi', nameEn: "New Year's Day", type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 1, 27), nameId: 'Isra Mikraj Nabi Muhammad SAW', nameEn: "Prophet's Ascension", type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 1, 29), nameId: 'Tahun Baru Imlek 2576', nameEn: 'Lunar New Year', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 3, 29), nameId: 'Hari Suci Nyepi (Tahun Baru Saka 1947)', nameEn: 'Nyepi Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 3, 30), nameId: 'Hari Raya Idul Fitri 1446 H', nameEn: 'Eid al-Fitr', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 3, 31), nameId: 'Hari Raya Idul Fitri 1446 H (Hari Kedua)', nameEn: 'Eid al-Fitr (Day 2)', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 4, 18), nameId: 'Wafat Yesus Kristus', nameEn: 'Good Friday', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 5, 1), nameId: 'Hari Buruh Internasional', nameEn: 'International Labour Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 5, 12), nameId: 'Hari Raya Waisak 2569 BE', nameEn: 'Vesak Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 5, 29), nameId: 'Kenaikan Yesus Kristus', nameEn: 'Ascension Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 6, 1), nameId: 'Hari Lahir Pancasila', nameEn: 'Pancasila Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 6, 6), nameId: 'Hari Raya Idul Adha 1446 H', nameEn: 'Eid al-Adha', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 6, 27), nameId: 'Tahun Baru Islam 1447 H', nameEn: 'Islamic New Year', type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 8, 17), nameId: 'HUT Kemerdekaan RI ke-80', nameEn: "Indonesia's 80th Independence Day", type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 9, 5), nameId: 'Maulid Nabi Muhammad SAW', nameEn: "Prophet's Birthday", type: HolidayType.national),
    HolidayEntity(date: DateTime(2025, 12, 25), nameId: 'Hari Raya Natal', nameEn: 'Christmas Day', type: HolidayType.national),

    HolidayEntity(date: DateTime(2025, 1, 28), nameId: 'Cuti Bersama Imlek', nameEn: 'Joint Leave – Lunar New Year', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2025, 3, 28), nameId: 'Cuti Bersama Idul Fitri', nameEn: 'Joint Leave – Eid', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2025, 4, 1), nameId: 'Cuti Bersama Idul Fitri', nameEn: 'Joint Leave – Eid', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2025, 4, 2), nameId: 'Cuti Bersama Idul Fitri', nameEn: 'Joint Leave – Eid', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2025, 4, 3), nameId: 'Cuti Bersama Idul Fitri', nameEn: 'Joint Leave – Eid', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2025, 4, 4), nameId: 'Cuti Bersama Idul Fitri', nameEn: 'Joint Leave – Eid', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2025, 5, 13), nameId: 'Cuti Bersama Waisak', nameEn: 'Joint Leave – Vesak', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2025, 5, 30), nameId: 'Cuti Bersama Kenaikan Yesus', nameEn: 'Joint Leave – Ascension', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2025, 12, 26), nameId: 'Cuti Bersama Natal', nameEn: 'Joint Leave – Christmas', type: HolidayType.cutiBersama),
  ];

  static final _holidays2026 = <HolidayEntity>[
    HolidayEntity(date: DateTime(2026, 1, 1), nameId: 'Tahun Baru Masehi', nameEn: "New Year's Day", type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 1, 17), nameId: 'Tahun Baru Imlek 2577', nameEn: 'Lunar New Year', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 3, 16), nameId: 'Isra Mikraj Nabi Muhammad SAW', nameEn: "Prophet's Ascension", type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 3, 19), nameId: 'Hari Raya Idul Fitri 1447 H', nameEn: 'Eid al-Fitr', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 3, 20), nameId: 'Hari Raya Idul Fitri 1447 H (Hari Kedua)', nameEn: 'Eid al-Fitr (Day 2)', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 3, 28), nameId: 'Hari Suci Nyepi (Tahun Baru Saka 1948)', nameEn: 'Nyepi Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 4, 3), nameId: 'Wafat Yesus Kristus', nameEn: 'Good Friday', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 5, 1), nameId: 'Hari Buruh Internasional', nameEn: 'International Labour Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 5, 14), nameId: 'Kenaikan Yesus Kristus', nameEn: 'Ascension Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 5, 21), nameId: 'Hari Raya Waisak 2570 BE', nameEn: 'Vesak Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 5, 26), nameId: 'Hari Raya Idul Adha 1447 H', nameEn: 'Eid al-Adha', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 6, 1), nameId: 'Hari Lahir Pancasila', nameEn: 'Pancasila Day', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 6, 16), nameId: 'Tahun Baru Islam 1448 H', nameEn: 'Islamic New Year', type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 8, 17), nameId: 'HUT Kemerdekaan RI ke-81', nameEn: "Indonesia's 81st Independence Day", type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 9, 25), nameId: 'Maulid Nabi Muhammad SAW', nameEn: "Prophet's Birthday", type: HolidayType.national),
    HolidayEntity(date: DateTime(2026, 12, 25), nameId: 'Hari Raya Natal', nameEn: 'Christmas Day', type: HolidayType.national),

    HolidayEntity(date: DateTime(2026, 1, 16), nameId: 'Cuti Bersama Imlek', nameEn: 'Joint Leave – Lunar New Year', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2026, 3, 18), nameId: 'Cuti Bersama Idul Fitri', nameEn: 'Joint Leave – Eid', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2026, 3, 23), nameId: 'Cuti Bersama Idul Fitri', nameEn: 'Joint Leave – Eid', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2026, 3, 24), nameId: 'Cuti Bersama Idul Fitri', nameEn: 'Joint Leave – Eid', type: HolidayType.cutiBersama),
    HolidayEntity(date: DateTime(2026, 12, 24), nameId: 'Cuti Bersama Natal', nameEn: 'Joint Leave – Christmas', type: HolidayType.cutiBersama),
  ];

  static Map<DateTime, List<HolidayEntity>> get holidayMap {
    final map = <DateTime, List<HolidayEntity>>{};
    for (final h in all) {
      final key = DateTime(h.date.year, h.date.month, h.date.day);
      (map[key] ??= []).add(h);
    }
    return map;
  }
}
