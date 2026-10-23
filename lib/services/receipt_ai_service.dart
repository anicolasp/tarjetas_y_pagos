import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/billing_cycle.dart';
import '../core/formatters.dart';
import '../core/money.dart';
import '../data/models/category.dart';
import '../data/repositories/expenses_repository.dart' show merchantMaxLength;
import 'picked_photo.dart';

export 'package:image_picker/image_picker.dart' show ImageSource;

/// What Claude read on a receipt, already validated. Any field may be null.
class ReceiptData {
  const ReceiptData({
    this.merchant,
    this.amountCents,
    this.currency,
    this.date,
    this.categoryId,
  });

  final String? merchant;
  final int? amountCents;
  final Currency? currency;
  final DateTime? date;
  final int? categoryId;

  /// The schema always yields a category, so only a merchant or an amount
  /// shows that the photo was really a readable receipt.
  bool get isEmpty => merchant == null && amountCents == null;
}

enum ReceiptScanError {
  offline('Sin conexión a internet. Completa el gasto a mano.'),
  timeout('La IA tardó demasiado. Intenta de nuevo o completa a mano.'),
  invalidKey('La clave de la IA no es válida. Completa el gasto a mano.'),
  rateLimited('La IA está recibiendo muchas solicitudes. Intenta en un rato.'),
  unavailable('La IA no está disponible ahora. Completa el gasto a mano.'),
  imageTooLarge('La foto es demasiado grande. Prueba con otra.'),
  invalidResponse('No pudimos leer la factura. Completa el gasto a mano.');

  const ReceiptScanError(this.message);

  /// Shown to the user. Never includes the API key or the response body.
  final String message;
}

sealed class ReceiptScanResult {
  const ReceiptScanResult();
}

class ReceiptScanRead extends ReceiptScanResult {
  const ReceiptScanRead(this.data);

  final ReceiptData data;
}

class ReceiptScanCancelled extends ReceiptScanResult {
  const ReceiptScanCancelled();
}

class ReceiptScanPermissionDenied extends ReceiptScanResult {
  const ReceiptScanPermissionDenied(this.source);

  final ImageSource source;
}

class ReceiptScanFailed extends ReceiptScanResult {
  const ReceiptScanFailed(this.error);

  final ReceiptScanError error;
}

abstract interface class ReceiptAiService {
  /// [categories] are the user's; the suggested one is always among them.
  /// [onReading] runs once a photo was chosen, right before sending it.
  Future<ReceiptScanResult> scan(
    ImageSource source, {
    required List<Category> categories,
    required DateTime today,
    void Function()? onReading,
  });

  /// Deletes photos left behind when Android closed the app mid-pick.
  Future<void> discardLostPhotos();
}

/// Reads a receipt photo with Claude (vision + structured outputs). The
/// photo is sent once, then deleted; it is never stored.
class ClaudeReceiptService implements ReceiptAiService {
  ClaudeReceiptService(
    this._apiKey, {
    http.Client? client,
    Future<String?> Function(ImageSource source)? pick,
    Future<List<String>> Function()? lostPhotos,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _pick = pick ?? _pickWithImagePicker,
       _lostPhotos = lostPhotos ?? lostPickedPhotos;

  static final endpoint = Uri.parse('https://api.anthropic.com/v1/messages');
  static const model = 'claude-sonnet-5-5';
  static const apiVersion = '2026-10-21';

  /// Retries policy declines on another model (Claude API only).
  static const fallbackBeta = 'server-side-fallback-2026-07-01';

  /// The API limit per image.
  static const maxImageBytes = 5 * 1024 * 1024;

  final String _apiKey;
  final http.Client _client;
  final Future<String?> Function(ImageSource source) _pick;
  final Future<List<String>> Function() _lostPhotos;
  final Duration timeout;

  /// About 1600 px on the long side: enough to read a receipt, small to
  /// send. The resized copy and the original are both deleted afterwards.
  static Future<String?> _pickWithImagePicker(ImageSource source) async =>
      (await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      ))?.path;

  @override
  Future<void> discardLostPhotos() => discardLostPickedPhotos(_lostPhotos);

  @override
  Future<ReceiptScanResult> scan(
    ImageSource source, {
    required List<Category> categories,
    required DateTime today,
    void Function()? onReading,
  }) async {
    await discardLostPhotos();
    final String? path;
    try {
      path = await _pick(source);
    } on PlatformException catch (e) {
      if (isPhotoPermissionDenied(e)) {
        return ReceiptScanPermissionDenied(source);
      }
      rethrow;
    }
    if (path == null) return const ReceiptScanCancelled();
    try {
      onReading?.call();
      final bytes = await File(path).readAsBytes();
      return await _read(bytes, categories, today);
    } finally {
      await deletePickedPhoto(path);
    }
  }

  Future<ReceiptScanResult> _read(
    Uint8List bytes,
    List<Category> categories,
    DateTime today,
  ) async {
    final mediaType = imageMediaType(bytes);
    if (mediaType == null) {
      return const ReceiptScanFailed(ReceiptScanError.invalidResponse);
    }
    if (bytes.length > maxImageBytes) {
      return const ReceiptScanFailed(ReceiptScanError.imageTooLarge);
    }
    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: {
              'content-type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': apiVersion,
              'anthropic-beta': fallbackBeta,
            },
            body: jsonEncode(
              requestBody(base64Encode(bytes), mediaType, categories),
            ),
          )
          .timeout(timeout);
    } on TimeoutException {
      return const ReceiptScanFailed(ReceiptScanError.timeout);
    } on SocketException {
      return const ReceiptScanFailed(ReceiptScanError.offline);
    } on http.ClientException {
      return const ReceiptScanFailed(ReceiptScanError.offline);
    }

    if (response.statusCode != 200) {
      return ReceiptScanFailed(switch (response.statusCode) {
        401 || 403 => ReceiptScanError.invalidKey,
        429 => ReceiptScanError.rateLimited,
        >= 500 => ReceiptScanError.unavailable,
        _ => ReceiptScanError.invalidResponse,
      });
    }
    final data = parseResponse(response.body, categories, today);
    if (data == null || data.isEmpty) {
      return const ReceiptScanFailed(ReceiptScanError.invalidResponse);
    }
    return ReceiptScanRead(data);
  }

  /// The Messages API request. The JSON schema makes the answer parseable;
  /// "" marks a field that cannot be read.
  static Map<String, Object?> requestBody(
    String base64Image,
    String mediaType,
    List<Category> categories,
  ) => {
    'model': model,
    'max_tokens': 4096,
    'fallbacks': 'default',
    'output_config': {
      'effort': 'low',
      'format': {
        'type': 'json_schema',
        'schema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['merchant', 'total', 'currency', 'date', 'category'],
          'properties': {
            'merchant': {
              'type': 'string',
              'description': 'Business name as printed, or "".',
            },
            'total': {
              'type': 'string',
              'description':
                  'Total paid, digits with "." as the decimal separator and '
                  'no thousands separator (e.g. "1234.50"), or "".',
            },
            'currency': {
              'type': 'string',
              'enum': ['DOP', 'USD', ''],
              'description': 'RD\$ or pesos is DOP; US\$ is USD.',
            },
            'date': {
              'type': 'string',
              'description': 'Purchase date as YYYY-MM-DD, or "".',
            },
            'category': {
              'type': 'string',
              'enum': [for (final c in categories) c.name],
              'description': 'The closest category for this purchase.',
            },
          },
        },
      },
    },
    'system':
        'You read receipts from the Dominican Republic for a personal '
        'expense app. Extract only what is printed on the receipt. If a '
        'field is not legible, use "". Dates on receipts are usually '
        'day/month/year.',
    'messages': [
      {
        'role': 'user',
        'content': [
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': mediaType,
              'data': base64Image,
            },
          },
          {'type': 'text', 'text': 'Extract the data from this receipt.'},
        ],
      },
    ],
  };

  /// The validated receipt data in a Messages API response, or null when
  /// the response is not usable (refusal, truncated, invalid JSON).
  static ReceiptData? parseResponse(
    String body,
    List<Category> categories,
    DateTime today,
  ) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      if (json['stop_reason'] != 'end_turn') return null;
      final text = [
        for (final b in json['content'] as List<Object?>)
          if (b is Map && b['type'] == 'text') b['text'] as String,
      ].join();
      final fields = jsonDecode(text) as Map<String, Object?>;
      return ReceiptData(
        merchant: _merchant(fields['merchant']),
        amountCents: _amount(fields['total']),
        currency: _currency(fields['currency']),
        date: _date(fields['date'], today),
        categoryId: _category(fields['category'], categories),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static String? _merchant(Object? v) {
    if (v is! String) return null;
    final s = v.trim();
    if (s.isEmpty) return null;
    return s.length > merchantMaxLength ? s.substring(0, merchantMaxLength) : s;
  }

  static int? _amount(Object? v) {
    if (v is! String) return null;
    final cents = parseMoneyToCents(v);
    return cents != null && cents > 0 ? cents : null;
  }

  static Currency? _currency(Object? v) => switch (v) {
    'DOP' => Currency.dop,
    'USD' => Currency.usd,
    _ => null,
  };

  static final _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// A real calendar date, not in the future and at most 5 years old (the
  /// same range the date picker offers).
  static DateTime? _date(Object? v, DateTime today) {
    if (v is! String) return null;
    final m = _isoDate.firstMatch(v.trim());
    if (m == null) return null;
    final (y, mo, d) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    final date = DateTime(y, mo, d);
    if (date.year != y || date.month != mo || date.day != d) return null;
    final day = dateOnly(today);
    if (dateOnly(date).isAfter(day) ||
        date.isBefore(DateTime(today.year - 5))) {
      return null;
    }
    return date;
  }

  /// One of the user's categories; anything else falls into "Otros".
  static int? _category(Object? v, List<Category> categories) {
    Category? named(String name) {
      for (final c in categories) {
        if (c.name.toLowerCase() == name.toLowerCase()) return c;
      }
      return null;
    }

    return (v is String ? named(v.trim()) : null)?.id ??
        named(fallbackCategory)?.id;
  }

  static const fallbackCategory = 'Otros';
}

/// JPEG, PNG, WebP or GIF by their first bytes; null for anything else.
String? imageMediaType(Uint8List b) {
  bool starts(List<int> sig, [int at = 0]) =>
      b.length >= at + sig.length &&
      [for (var i = 0; i < sig.length; i++) b[at + i] == sig[i]]
          .every((x) => x);
  if (starts([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (starts([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  if (starts([0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  return null;
}
