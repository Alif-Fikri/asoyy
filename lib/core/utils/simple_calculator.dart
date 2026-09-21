class _Parser {
  final String text;
  int pos = 0;

  _Parser(this.text);

  void _skipSpaces() {
    while (pos < text.length && text[pos] == ' ') {
      pos++;
    }
  }

  double? parse() {
    _skipSpaces();
    final value = _parseExpression();
    _skipSpaces();
    if (value == null || pos != text.length) return null;
    return value;
  }

  double? _parseExpression() {
    var left = _parseTerm();
    if (left == null) return null;
    while (true) {
      _skipSpaces();
      if (pos >= text.length) break;
      final op = text[pos];
      if (op != '+' && op != '-') break;
      pos++;
      final right = _parseTerm();
      if (right == null) return null;
      left = op == '+' ? left! + right : left! - right;
    }
    return left;
  }

  double? _parseTerm() {
    var left = _parseFactor();
    if (left == null) return null;
    while (true) {
      _skipSpaces();
      if (pos >= text.length) break;
      final op = text[pos];
      if (op != '*' && op != '/') break;
      pos++;
      final right = _parseFactor();
      if (right == null) return null;
      if (op == '/' && right == 0) return null;
      left = op == '*' ? left! * right : left! / right;
    }
    return left;
  }

  double? _parseFactor() {
    _skipSpaces();
    if (pos < text.length && text[pos] == '-') {
      pos++;
      final value = _parseFactor();
      return value == null ? null : -value;
    }
    if (pos < text.length && text[pos] == '(') {
      pos++;
      final value = _parseExpression();
      _skipSpaces();
      if (value == null || pos >= text.length || text[pos] != ')') return null;
      pos++;
      return value;
    }
    return _parseNumber();
  }

  double? _parseNumber() {
    _skipSpaces();
    final start = pos;
    while (pos < text.length && (_isDigit(text[pos]) || text[pos] == '.')) {
      pos++;
    }
    if (pos == start) return null;
    return double.tryParse(text.substring(start, pos));
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

double? evaluateExpression(String expression) {
  final cleaned = expression.replaceAll(',', '.').trim();
  if (cleaned.isEmpty) return null;
  return _Parser(cleaned).parse();
}
