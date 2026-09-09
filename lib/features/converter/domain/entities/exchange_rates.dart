class ExchangeRates {
  final String base;
  final Map<String, double> rates;
  final DateTime fetchedAt;

  const ExchangeRates({
    required this.base,
    required this.rates,
    required this.fetchedAt,
  });

  bool isStaleAt(DateTime now, Duration ttl) =>
      now.difference(fetchedAt) > ttl;
}
