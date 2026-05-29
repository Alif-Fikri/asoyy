enum HolidayType { national, cutiBersama }

class HolidayEntity {
  final DateTime date;
  final String nameId;
  final String nameEn;
  final HolidayType type;

  const HolidayEntity({
    required this.date,
    required this.nameId,
    required this.nameEn,
    required this.type,
  });

  bool get isNational => type == HolidayType.national;
}

class PaydayMarker {
  const PaydayMarker();
}
