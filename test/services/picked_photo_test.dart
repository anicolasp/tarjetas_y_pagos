import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/services/picked_photo.dart';

/// Mirrors image_picker's Android cache layout.
void main() {
  late Directory cache;
  const uuid = 'c8a2b80a-bc30-4dae-83bc-a2c1f4cd63e6';

  setUp(() async => cache = await Directory.systemTemp.createTemp('cache'));
  tearDown(() => cache.delete(recursive: true));

  Future<File> write(String relative) async {
    final f = File('${cache.path}/$relative');
    await f.parent.create(recursive: true);
    return f.writeAsBytes([1]);
  }

  test('a gallery copy and its uuid folder are deleted', () async {
    final copy = await write('$uuid/1000000018.jpg');
    await deletePickedPhoto(copy.path);
    expect(copy.existsSync(), isFalse);
    expect(Directory('${cache.path}/$uuid').existsSync(), isFalse);
    expect(cache.existsSync(), isTrue);
  });

  test('a resized photo also deletes the original copy it came from', () async {
    final original = await write('$uuid/1000000018.jpg');
    final scaled = await write('scaled_1000000018.jpg');
    final unrelated = await write(
      'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/other.jpg',
    );

    await deletePickedPhoto(scaled.path);

    expect(scaled.existsSync(), isFalse);
    expect(original.existsSync(), isFalse);
    expect(Directory('${cache.path}/$uuid').existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
  });

  test('a uuid folder with other files is not touched', () async {
    final original = await write('$uuid/1000000018.jpg');
    final neighbour = await write('$uuid/other.jpg');
    final scaled = await write('scaled_1000000018.jpg');
    await deletePickedPhoto(scaled.path);
    expect(scaled.existsSync(), isFalse);
    expect(original.existsSync(), isTrue);
    expect(neighbour.existsSync(), isTrue);
  });

  test('a camera photo in the cache root leaves the root alone', () async {
    final photo = await write('image_picker123.jpg');
    await deletePickedPhoto(photo.path);
    expect(photo.existsSync(), isFalse);
    expect(cache.existsSync(), isTrue);
  });

  test('a missing file does not throw', () async {
    await deletePickedPhoto('${cache.path}/scaled_gone.jpg');
  });

  test('lost photos are deleted; a failing lookup is swallowed', () async {
    final lost = await write('lost.jpg');
    await discardLostPickedPhotos(() async => [lost.path]);
    expect(lost.existsSync(), isFalse);
    await discardLostPickedPhotos(() async => throw Exception('no plugin'));
  });
}
