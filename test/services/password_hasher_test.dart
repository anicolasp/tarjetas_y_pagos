import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/services/password_hasher.dart';

void main() {
  const hasher = PasswordHasher(iterations: 1000, useIsolate: false);
  const password = 'abc12345';

  test('salts are random and 16 bytes', () {
    final a = hasher.newSalt();
    final b = hasher.newSalt();
    expect(a, isNot(b));
    expect(base64Decode(a), hasLength(16));
  });

  test('never stores the password in plain text', () async {
    final stored = await hasher.hash(password, hasher.newSalt());
    expect(stored, startsWith(r'pbkdf2-sha256$1000$'));
    expect(stored, isNot(contains(password)));
    expect(stored, isNot(contains(base64Encode(utf8.encode(password)))));
  });

  test('same password with different salt gives different hashes', () async {
    final a = await hasher.hash(password, hasher.newSalt());
    final b = await hasher.hash(password, hasher.newSalt());
    expect(a, isNot(b));
  });

  test('verify accepts the right password only', () async {
    final salt = hasher.newSalt();
    final stored = await hasher.hash(password, salt);
    expect(await hasher.verify(password, salt, stored), isTrue);
    expect(await hasher.verify('abc12346', salt, stored), isFalse);
    expect(await hasher.verify(password, hasher.newSalt(), stored), isFalse);
  });

  test('verify uses the iterations stored in the hash', () async {
    const old = PasswordHasher(iterations: 500, useIsolate: false);
    final salt = hasher.newSalt();
    final stored = await old.hash(password, salt);
    expect(await hasher.verify(password, salt, stored), isTrue);
    expect(hasher.needsRehash(stored), isTrue);
    expect(hasher.needsRehash(await hasher.hash(password, salt)), isFalse);
  });

  test('malformed hashes never verify', () async {
    final salt = hasher.newSalt();
    for (final bad in [
      '',
      'plain',
      r'md5$1$abc',
      r'pbkdf2-sha256$x$abc',
      r'pbkdf2-sha256$1000$!!!not-base64',
    ]) {
      expect(await hasher.verify(password, salt, bad), isFalse, reason: bad);
    }
  });

  test('a corrupted salt never verifies (no exception)', () async {
    final stored = await hasher.hash(password, hasher.newSalt());
    expect(await hasher.verify(password, '%%%', stored), isFalse);
  });

  test('works in a background isolate', () async {
    const isolated = PasswordHasher(iterations: 1000);
    final salt = isolated.newSalt();
    final stored = await isolated.hash(password, salt);
    expect(await isolated.verify(password, salt, stored), isTrue);
  });
}
