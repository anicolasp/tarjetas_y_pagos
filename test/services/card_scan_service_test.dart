import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';
import 'package:tarjetas_y_pagos/services/card_scan_service.dart';

void main() {
  late Directory tmp;
  late File photo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('scan_test');
    photo = await File('${tmp.path}/card.jpg').writeAsBytes([1, 2, 3]);
  });
  tearDown(() => tmp.delete(recursive: true));

  MlKitCardScanService service(String ocr) => MlKitCardScanService(
    pick: (_) async => photo.path,
    recognize: (_) async => ocr,
  );

  test(
    'returns only last 4, brand and bank; the full number stays inside',
    () async {
      final result = await service('BANCO POPULAR 4111 1111 1111 1111 12/28')
          .scan(ImageSource.gallery);

      final d = (result as CardScanDetected).detection;
      expect(d.last4, '1111');
      expect(d.brand, CardBrand.visa);
      expect(d.bank, 'Banco Popular');
      // Nothing in what comes out holds more than the last 4 digits.
      final exposed = '${d.last4}|${d.brand}|${d.bank}|$d|$result';
      expect(exposed, isNot(contains('41111111')));
      expect(exposed, isNot(contains('4111 1111')));
    },
  );

  test('the photo is deleted after reading it', () async {
    await service('4111 1111 1111 1111').scan(ImageSource.camera);
    expect(photo.existsSync(), isFalse);
  });

  test('the photo is deleted even when the OCR fails', () async {
    final failing = MlKitCardScanService(
      pick: (_) async => photo.path,
      recognize: (_) async => throw Exception('ML Kit'),
    );
    await expectLater(failing.scan(ImageSource.camera), throwsException);
    expect(photo.existsSync(), isFalse);
  });

  test('nothing readable', () async {
    expect(
      await service('ANA PEREZ').scan(ImageSource.gallery),
      isA<CardScanNothing>(),
    );
    expect(photo.existsSync(), isFalse);
  });

  test('closing the picker is a cancel', () async {
    final s = MlKitCardScanService(
      pick: (_) async => null,
      recognize: (_) async => fail('must not read'),
    );
    expect(await s.scan(ImageSource.camera), isA<CardScanCancelled>());
  });

  test('camera permission denied', () async {
    final s = MlKitCardScanService(
      pick: (_) async => throw PlatformException(code: 'camera_access_denied'),
      recognize: (_) async => fail('must not read'),
    );
    expect(await s.scan(ImageSource.camera), isA<CardScanPermissionDenied>());
  });

  test('other picker errors are not swallowed', () async {
    final s = MlKitCardScanService(
      pick: (_) async => throw PlatformException(code: 'no_available_camera'),
      recognize: (_) async => fail('must not read'),
    );
    await expectLater(
      s.scan(ImageSource.camera),
      throwsA(isA<PlatformException>()),
    );
  });
}
