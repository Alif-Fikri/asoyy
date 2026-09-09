import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../domain/entities/exchange_rates.dart';

class ConverterRatesRepository {
  static const _ratesKey = 'converter_rates_json';
  static const _fetchedAtKey = 'converter_rates_fetched_at';
  static const ttl = Duration(hours: 12);
  static const _endpoint = 'https://open.er-api.com/v6/latest/USD';

  Box get _box => Hive.box(AppConstants.settingsBox);

  ExchangeRates? getCached() {
    final raw = _box.get(_ratesKey) as String?;
    final fetchedMs = _box.get(_fetchedAtKey) as int?;
    if (raw == null || fetchedMs == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return ExchangeRates(
      base: 'USD',
      rates: decoded.map((k, v) => MapEntry(k, (v as num).toDouble())),
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetchedMs),
    );
  }

  Future<ExchangeRates> fetchAndCache() async {
    final response = await http
        .get(Uri.parse(_endpoint))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil kurs (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = (body['rates'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
    final fetchedAt = DateTime.now();
    await _box.put(_ratesKey, jsonEncode(rates));
    await _box.put(_fetchedAtKey, fetchedAt.millisecondsSinceEpoch);
    return ExchangeRates(base: 'USD', rates: rates, fetchedAt: fetchedAt);
  }
}
