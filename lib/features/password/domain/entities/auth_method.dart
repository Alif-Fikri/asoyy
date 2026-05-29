enum AuthMethod {
  biometric,
  pattern,
  pin;

  static AuthMethod? fromString(String? value) {
    if (value == null) return null;
    for (final m in AuthMethod.values) {
      if (m.name == value) return m;
    }
    return null;
  }
}
