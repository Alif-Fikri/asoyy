enum UnitCategory { length, weight, temperature, volume }

class UnitDef {
  final String code;
  final String label;

  const UnitDef(this.code, this.label);
}

const _lengthFactors = {
  'mm': 0.001,
  'cm': 0.01,
  'm': 1.0,
  'km': 1000.0,
  'in': 0.0254,
  'ft': 0.3048,
  'yd': 0.9144,
  'mi': 1609.344,
};

const _weightFactors = {
  'mg': 0.000001,
  'g': 0.001,
  'kg': 1.0,
  'ton': 1000.0,
  'oz': 0.0283495,
  'lb': 0.453592,
};

const _volumeFactors = {
  'ml': 0.001,
  'l': 1.0,
  'm3': 1000.0,
  'gal': 3.78541,
  'cup': 0.24,
};

const _temperatureUnits = ['c', 'f', 'k'];

List<UnitDef> unitsFor(UnitCategory category, {
  required String Function(String) labelOf,
}) {
  final codes = switch (category) {
    UnitCategory.length => _lengthFactors.keys,
    UnitCategory.weight => _weightFactors.keys,
    UnitCategory.volume => _volumeFactors.keys,
    UnitCategory.temperature => _temperatureUnits,
  };
  return codes.map((c) => UnitDef(c, labelOf(c))).toList();
}

double convertUnit(UnitCategory category, String from, String to, double value) {
  if (from == to) return value;
  switch (category) {
    case UnitCategory.length:
      return value * _lengthFactors[from]! / _lengthFactors[to]!;
    case UnitCategory.weight:
      return value * _weightFactors[from]! / _weightFactors[to]!;
    case UnitCategory.volume:
      return value * _volumeFactors[from]! / _volumeFactors[to]!;
    case UnitCategory.temperature:
      final celsius = switch (from) {
        'c' => value,
        'f' => (value - 32) * 5 / 9,
        'k' => value - 273.15,
        _ => value,
      };
      return switch (to) {
        'c' => celsius,
        'f' => celsius * 9 / 5 + 32,
        'k' => celsius + 273.15,
        _ => celsius,
      };
  }
}
