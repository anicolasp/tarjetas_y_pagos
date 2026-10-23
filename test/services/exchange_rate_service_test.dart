import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/services/exchange_rate_service.dart';

class FakeSource implements ExchangeRateSource {
  FakeSource(this.micros);

  int? micros;
  var calls = 0;

  @override
  Future<int> fetchUsdToDopMicros() async {
    calls++;
    if (micros == null) throw Exception('sin internet');
    return micros!;
  }
}

void main() {
  late DateTime now;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 10, 22, 10);
  });

  ExchangeRateService service(FakeSource source) =>
      ExchangeRateService(source, prefs, clock: () => now);

  test('fetches online and caches for 12 hours', () async {
    final source = FakeSource(61409228);
    final s = service(source);
    expect((await s.usdToDop())!.usdToDopMicros, 61409228);
    source.micros = 62000000;
    now = now.add(const Duration(hours: 11));
    expect((await s.usdToDop())!.usdToDopMicros, 61409228);
    expect(source.calls, 1);
    now = now.add(const Duration(hours: 2));
    expect((await s.usdToDop())!.usdToDopMicros, 62000000);
    expect(source.calls, 2);
  });

  test('offline: falls back to the last known rate, marked stale', () async {
    final source = FakeSource(61409228);
    final s = service(source);
    await s.usdToDop();
    source.micros = null;
    now = now.add(const Duration(days: 2));
    final quote = (await s.usdToDop())!;
    expect(quote.usdToDopMicros, 61409228);
    expect(quote.stale, isTrue);
  });

  test('offline and never fetched: null', () async {
    expect(await service(FakeSource(null)).usdToDop(), isNull);
  });

  group('OpenErApiSource', () {
    OpenErApiSource source(int status, Object body) => OpenErApiSource(
      MockClient((request) async {
        expect(request.url.host, 'open.er-api.com');
        return http.Response(jsonEncode(body), status);
      }),
    );

    test('parses the DOP rate into micros', () async {
      final micros = await source(200, {
        'result': 'success',
        'rates': {'USD': 1, 'DOP': 61.409228},
      }).fetchUsdToDopMicros();
      expect(micros, 61409228);
    });

    test('rejects errors, missing DOP and absurd rates', () async {
      for (final (status, body) in [
        (500, {'result': 'error'}),
        (200, {'result': 'error'}),
        (
          200,
          {
            'result': 'success',
            'rates': {'USD': 1},
          },
        ),
        (
          200,
          {
            'result': 'success',
            'rates': {'DOP': 0.5},
          },
        ),
        (
          200,
          {
            'result': 'success',
            'rates': {'DOP': 5000},
          },
        ),
      ]) {
        await expectLater(
          source(status, body).fetchUsdToDopMicros(),
          throwsA(anything),
          reason: '$status $body',
        );
      }
    });
  });
}
