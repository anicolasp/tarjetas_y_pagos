import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/money.dart';

/// Where today's US$→RD$ rate comes from. Tests use a fake.
abstract interface class ExchangeRateSource {
  /// RD$ per US$ x 1,000,000. Throws on network or format errors.
  Future<int> fetchUsdToDopMicros();
}

/// open.er-api.com (ExchangeRate-API open access): free, no key, updated
/// daily, includes DOP. Only the currency pair is sent; no user data.
class OpenErApiSource implements ExchangeRateSource {
  OpenErApiSource([http.Client? client]) : _client = client ?? http.Client();

  static final url = Uri.parse('https://open.er-api.com/v6/latest/USD');
  static const timeout = Duration(seconds: 5);

  final http.Client _client;

  @override
  Future<int> fetchUsdToDopMicros() async {
    final response = await _client.get(url).timeout(timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', url);
    }
    final body = jsonDecode(response.body) as Map<String, Object?>;
    final rate = (body['rates'] as Map<String, Object?>?)?['DOP'];
    if (body['result'] != 'success' || rate is! num) {
      throw const FormatException('Respuesta de tasa no válida');
    }
    final micros = (rate * rateScale).round();
    // Sanity range for RD$ per US$; anything else is a bad response.
    if (micros < 1 * rateScale || micros > 1000 * rateScale) {
      throw FormatException('Tasa fuera de rango: $rate');
    }
    return micros;
  }
}

class RateQuote {
  const RateQuote({
    required this.usdToDopMicros,
    required this.fetchedAt,
    required this.stale,
  });

  final int usdToDopMicros;
  final DateTime fetchedAt;

  /// The online fetch failed and this is the last known rate.
  final bool stale;
}

/// Today's US$→RD$ rate: cached for [ttl], refreshed online, and falling
/// back to the last known rate when offline.
class ExchangeRateService {
  ExchangeRateService(this._source, this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const ttl = Duration(hours: 12);
  static const _rateKey = 'fx.usd_dop.micros';
  static const _atKey = 'fx.usd_dop.at';

  final ExchangeRateSource _source;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  /// Null only when the rate was never fetched and the fetch fails now.
  Future<RateQuote?> usdToDop() async {
    final cached = _cached();
    if (cached != null && _clock().difference(cached.fetchedAt) < ttl) {
      return cached;
    }
    try {
      final micros = await _source.fetchUsdToDopMicros();
      final now = _clock();
      await _prefs.setInt(_rateKey, micros);
      await _prefs.setInt(_atKey, now.millisecondsSinceEpoch);
      return RateQuote(usdToDopMicros: micros, fetchedAt: now, stale: false);
    } on Object {
      return cached == null
          ? null
          : RateQuote(
              usdToDopMicros: cached.usdToDopMicros,
              fetchedAt: cached.fetchedAt,
              stale: true,
            );
    }
  }

  RateQuote? _cached() {
    final micros = _prefs.getInt(_rateKey);
    final at = _prefs.getInt(_atKey);
    if (micros == null || at == null) return null;
    return RateQuote(
      usdToDopMicros: micros,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(at),
      stale: false,
    );
  }
}
