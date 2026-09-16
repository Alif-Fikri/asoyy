String formatCalculatorDisplay(String raw) {
  if (raw.isEmpty) return raw;

  final negative = raw.startsWith('-');
  final body = negative ? raw.substring(1) : raw;
  final dotIndex = body.indexOf('.');
  final intPart = dotIndex == -1 ? body : body.substring(0, dotIndex);
  final decimalPart = dotIndex == -1 ? '' : body.substring(dotIndex);

  final digits = intPart.isEmpty ? '0' : intPart;
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }

  return '${negative ? '-' : ''}${buf.toString()}$decimalPart';
}

final _numberToken = RegExp(r'^-?\d+(\.\d*)?$');

String formatCalculatorExpression(String expression) {
  if (expression.isEmpty) return expression;
  return expression
      .split(' ')
      .map((token) => _numberToken.hasMatch(token) ? formatCalculatorDisplay(token) : token)
      .join(' ');
}

int rawIndexToFormattedIndex(String raw, int rawIndex) {
  final formatted = formatCalculatorDisplay(raw);
  final clamped = rawIndex.clamp(0, raw.length);
  var consumed = 0;
  for (var fi = 0; fi <= formatted.length; fi++) {
    if (consumed == clamped) return fi;
    if (fi == formatted.length) break;
    if (formatted[fi] != ',') consumed++;
  }
  return formatted.length;
}

int formattedIndexToRawIndex(String formatted, int formattedIndex) {
  final clamped = formattedIndex.clamp(0, formatted.length);
  var count = 0;
  for (var i = 0; i < clamped; i++) {
    if (formatted[i] != ',') count++;
  }
  return count;
}
