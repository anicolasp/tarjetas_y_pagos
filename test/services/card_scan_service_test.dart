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

  test('a gallery copy in its own uuid folder: folder removed too', () async {
    final folder = await Directory(
      '${tmp.path}/c8a2b80a-bc30-4dae-83bc-a2c1f4cd63e6',
    ).create();
    final copy = await File('${folder.path}/1000000018.jpg').writeAsBytes([1]);
    await MlKitCardScanService(
      pick: (_) async => copy.path,
      recognize: (_) async => '4111 1111 1111 1111',
    ).scan(ImageSource.gallery);
    expect(copy.existsSync(), isFalse);
    expect(folder.existsSync(), isFalse);
    expect(tmp.existsSync(), isTrue);
  });

  test('other folders are never removed', () async {
    await service('4111 1111 1111 1111').scan(ImageSource.camera);
    expect(photo.existsSync(), isFalse);
    expect(tmp.existsSync(), isTrue); // not a uuid folder
  });

  test('a uuid folder with other files is kept', () async {
    final folder = await Directory(
      '${tmp.path}/c8a2b80a-bc30-4dae-83bc-a2c1f4cd63e6',
    ).create();
    final copy = await File('${folder.path}/a.jpg').writeAsBytes([1]);
    final other = await File('${folder.path}/b.jpg').writeAsBytes([1]);
    await MlKitCardScanService(
      pick: (_) async => copy.path,
      recognize: (_) async => '',
    ).scan(ImageSource.gallery);
    expect(copy.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
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

  test('onReading runs after a photo is chosen, before the OCR', () async {
    final events = <String>[];
    await MlKitCardScanService(
      pick: (_) async {
        events.add('pick');
        return photo.path;
      },
      recognize: (_) async {
        events.add('ocr');
        return '';
      },
    ).scan(ImageSource.gallery, onReading: () => events.add('reading'));
    expect(events, ['pick', 'reading', 'ocr']);
  });

  test('onReading does not run on cancel or denied permission', () async {
    var reading = 0;
    await MlKitCardScanService(
      pick: (_) async => null,
      recognize: (_) async => '',
    ).scan(ImageSource.camera, onReading: () => reading++);
    await MlKitCardScanService(
      pick: (_) async => throw PlatformException(code: 'camera_access_denied'),
      recognize: (_) async => '',
    ).scan(ImageSource.camera, onReading: () => reading++);
    expect(reading, 0);
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
