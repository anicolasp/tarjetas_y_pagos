import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/models/category.dart';
import 'package:tarjetas_y_pagos/services/receipt_ai_service.dart';

const _key = 'sk-ant-test-SECRET-123';
final _today = DateTime(2026, 10, 22, 10);
const _categories = [
  Category(id: 1, name: 'Supermercado', icon: 'cart', color: 0),
  Category(id: 2, name: 'Combustible', icon: 'fuel', color: 0),
  Category(id: 13, name: 'Otros', icon: 'category', color: 0),
];

/// A Messages API response whose text block is [fields] as JSON.
String _response(
  Map<String, Object?> fields, {
  String stopReason = 'end_turn',
}) => jsonEncode({
  'id': 'msg_test',
  'type': 'message',
  'role': 'assistant',
  'model': 'claude-sonnet-5-5',
  'content': [
    {'type': 'thinking', 'thinking': '', 'signature': 'sig'},
    {'type': 'text', 'text': jsonEncode(fields)},
  ],
  'stop_reason': stopReason,
  'usage': {'input_tokens': 1000, 'output_tokens': 50},
});

/// A minimal JPEG header is enough for the media type check.
const _jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3];

const _valid = {
  'merchant': 'Supermercado Ficticio',
  'total': '1234.50',
  'currency': 'DOP',
  'date': '2026-10-20',
  'category': 'Supermercado',
};

void main() {
  late Directory tmp;
  late File photo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('receipt_test');
    photo = File('${tmp.path}/receipt.jpg');
  });
  tearDown(() => tmp.delete(recursive: true));

  ClaudeReceiptService service(
    http.Client client, {
    Duration timeout = const Duration(seconds: 30),
  }) => ClaudeReceiptService(
    _key,
    client: client,
    pick: (_) async => (await photo.writeAsBytes(_jpeg)).path,
    lostPhotos: () async => const [],
    timeout: timeout,
  );

  Future<ReceiptScanResult> scan(http.Client client) =>
      service(client)
          .scan(ImageSource.gallery, categories: _categories, today: _today);

  ReceiptScanError errorOf(ReceiptScanResult r) =>
      (r as ReceiptScanFailed).error;

  test('a valid response fills every field', () async {
    late http.Request sent;
    final result = await scan(
      MockClient((request) async {
        sent = request;
        return http.Response(_response(_valid), 200);
      }),
    );

    final data = (result as ReceiptScanRead).data;
    expect(data.merchant, 'Supermercado Ficticio');
    expect(data.amountCents, 123450);
    expect(data.currency, Currency.dop);
    expect(data.date, DateTime(2026, 10, 20));
    expect(data.categoryId, 1);

    expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(sent.headers['x-api-key'], _key);
    expect(sent.headers['anthropic-version'], '2026-10-21');
    final body = jsonDecode(sent.body) as Map<String, Object?>;
    expect(body['model'], 'claude-sonnet-5-5');
    expect(body.containsKey('tool_choice'), isFalse); // 400 on Sonnet 5.5
    final schema =
        ((body['output_config'] as Map)['format'] as Map)['schema'] as Map;
    expect(((schema['properties'] as Map)['category'] as Map)['enum'], [
      'Supermercado',
      'Combustible',
      'Otros',
    ]);
    final image = ((body['messages'] as List).single['content'] as List).first;
    expect(image['source']['media_type'], 'image/jpeg');
    expect(image['source']['data'], base64Encode(_jpeg));
  });

  test('an unknown category falls into "Otros"', () async {
    final result = await scan(
      MockClient(
        (_) async =>
            http.Response(_response({..._valid, 'category': 'Juguetes'}), 200),
      ),
    );
    expect((result as ReceiptScanRead).data.categoryId, 13);
  });

  test('unreadable fields stay empty; the rest is kept', () async {
    final result = await scan(
      MockClient(
        (_) async => http.Response(
          _response({
            'merchant': '  Bomba Ficticia  ',
            'total': '1500,50', // a decimal comma is ambiguous: dropped
            'currency': '',
            'date': '2026-02-30', // not a real date
            'category': 'Combustible',
          }),
          200,
        ),
      ),
    );
    final data = (result as ReceiptScanRead).data;
    expect(data.merchant, 'Bomba Ficticia');
    expect(data.amountCents, isNull);
    expect(data.currency, isNull);
    expect(data.date, isNull);
    expect(data.categoryId, 2);
  });

  test(
    'amounts must be > 0 and dates not future nor older than 5 years',
    () async {
      for (final (total, date) in [
        ('0', '2026-10-23'),
        ('0.00', '2020-12-31'),
        ('12345678901', '2026-13-01'),
      ]) {
        final result = await scan(
          MockClient(
            (_) async => http.Response(
              _response({..._valid, 'total': total, 'date': date}),
              200,
            ),
          ),
        );
        final data = (result as ReceiptScanRead).data;
        expect(data.amountCents, isNull, reason: total);
        expect(data.date, isNull, reason: date);
      }
      final oldest = await scan(
        MockClient(
          (_) async => http.Response(
            _response({..._valid, 'date': '2021-01-01', 'total': '1,234.50'}),
            200,
          ),
        ),
      );
      expect((oldest as ReceiptScanRead).data.date, DateTime(2021));
      expect(oldest.data.amountCents, 123450);
    },
  );

  test('invalid JSON, refusal and truncation are invalid responses', () async {
    for (final body in [
      'not json',
      jsonEncode({
        'content': [
          {'type': 'text', 'text': '{"merchant": '},
        ],
        'stop_reason': 'end_turn',
      }),
      _response(_valid, stopReason: 'refusal'),
      _response(_valid, stopReason: 'max_tokens'),
      jsonEncode({'content': 'x', 'stop_reason': 'end_turn'}),
      _response({
        'merchant': '',
        'total': '',
        'currency': '',
        'date': '',
        'category': 'Nada',
      }).replaceAll('"Nada"', '""'),
    ]) {
      final result = await scan(
        MockClient((_) async => http.Response(body, 200)),
      );
      expect(errorOf(result), ReceiptScanError.invalidResponse, reason: body);
    }
  });

  test('without a merchant or an amount nothing was read', () async {
    final result = await scan(
      MockClient(
        (_) async => http.Response(
          _response({..._valid, 'merchant': '', 'total': ''}),
          200,
        ),
      ),
    );
    expect(errorOf(result), ReceiptScanError.invalidResponse);
  });

  test('HTTP errors map to messages', () async {
    const cases = {
      401: ReceiptScanError.invalidKey,
      403: ReceiptScanError.invalidKey,
      429: ReceiptScanError.rateLimited,
      500: ReceiptScanError.unavailable,
      529: ReceiptScanError.unavailable,
      400: ReceiptScanError.invalidResponse,
    };
    for (final MapEntry(key: status, value: error) in cases.entries) {
      final result = await scan(
        MockClient(
          (_) async => http.Response('{"type":"error","error":{}}', status),
        ),
      );
      expect(errorOf(result), error, reason: '$status');
    }
  });

  test('timeout', () async {
    final result = await service(
      MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
    ).scan(ImageSource.gallery, categories: _categories, today: _today);
    expect(errorOf(result), ReceiptScanError.timeout);
  });

  test('no internet', () async {
    for (final e in <Exception>[
      const SocketException('Failed host lookup'),
      http.ClientException('Connection refused'),
    ]) {
      final result = await scan(MockClient((_) async => throw e));
      expect(errorOf(result), ReceiptScanError.offline);
    }
  });

  test('the key never appears in any error message', () {
    for (final e in ReceiptScanError.values) {
      expect(e.message, isNot(contains(_key)));
      expect(e.message, isNot(contains('sk-ant')));
    }
  });

  test('the photo is deleted on success and on every failure', () async {
    for (final client in [
      MockClient((_) async => http.Response(_response(_valid), 200)),
      MockClient((_) async => http.Response('', 401)),
      MockClient((_) async => throw const SocketException('offline')),
    ]) {
      await scan(client);
      expect(photo.existsSync(), isFalse);
    }
  });

  test('not an image: nothing is sent', () async {
    var calls = 0;
    final result = await ClaudeReceiptService(
      _key,
      client: MockClient((_) async {
        calls++;
        return http.Response(_response(_valid), 200);
      }),
      pick: (_) async => (await photo.writeAsBytes([1, 2, 3, 4])).path,
      lostPhotos: () async => const [],
    ).scan(ImageSource.gallery, categories: _categories, today: _today);
    expect(errorOf(result), ReceiptScanError.invalidResponse);
    expect(calls, 0);
  });

  test('cancel, denied permission and onReading order', () async {
    final events = <String>[];
    final cancelled =
        await ClaudeReceiptService(
          _key,
          client: MockClient((_) async => fail('must not send')),
          pick: (_) async => null,
          lostPhotos: () async => const [],
        ).scan(
          ImageSource.camera,
          categories: _categories,
          today: _today,
          onReading: () => events.add('reading'),
        );
    expect(cancelled, isA<ReceiptScanCancelled>());

    final denied = await ClaudeReceiptService(
      _key,
      client: MockClient((_) async => fail('must not send')),
      pick: (_) async => throw PlatformException(code: 'camera_access_denied'),
      lostPhotos: () async => const [],
    ).scan(ImageSource.camera, categories: _categories, today: _today);
    expect((denied as ReceiptScanPermissionDenied).source, ImageSource.camera);
    expect(events, isEmpty);

    await ClaudeReceiptService(
      _key,
      client: MockClient((_) async {
        events.add('send');
        return http.Response(_response(_valid), 200);
      }),
      pick: (_) async => (await photo.writeAsBytes(_jpeg)).path,
      lostPhotos: () async => const [],
    ).scan(
      ImageSource.gallery,
      categories: _categories,
      today: _today,
      onReading: () => events.add('reading'),
    );
    expect(events, ['reading', 'send']);
  });

  test('media types by magic bytes', () {
    expect(
      imageMediaType(Uint8List.fromList([0xFF, 0xD8, 0xFF])),
      'image/jpeg',
    );
    expect(
      imageMediaType(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0])),
      'image/png',
    );
    expect(
      imageMediaType(Uint8List.fromList('RIFF0000WEBP'.codeUnits)),
      'image/webp',
    );
    expect(imageMediaType(Uint8List.fromList('GIF89a'.codeUnits)), 'image/gif');
    expect(imageMediaType(Uint8List.fromList([0, 1, 2])), isNull);
  });
}
