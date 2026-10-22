import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

void main() {
  const email = 'ana@example.com';
  late DateTime now;
  late LoginThrottle throttle;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 22, 9);
    throttle = LoginThrottle(
      await SharedPreferences.getInstance(),
      clock: () => now,
    );
  });

  Future<void> fail(int times) async {
    for (var i = 0; i < times; i++) {
      await throttle.registerFailure(email);
    }
  }

  test('4 failures do not lock', () async {
    await fail(4);
    expect(throttle.lockedFor(email), isNull);
  });

  test('5 failures lock for 30 s, then it can try again', () async {
    await fail(5);
    expect(throttle.lockedFor(email), const Duration(seconds: 30));
    now = now.add(const Duration(seconds: 29));
    expect(throttle.lockedFor(email), const Duration(seconds: 1));
    now = now.add(const Duration(seconds: 1));
    expect(throttle.lockedFor(email), isNull);
  });

  test('lockouts grow: 30 s, 60 s, 120 s', () async {
    await fail(5);
    now = now.add(const Duration(minutes: 1));
    await fail(5);
    expect(throttle.lockedFor(email), const Duration(seconds: 60));
    now = now.add(const Duration(minutes: 2));
    await fail(5);
    expect(throttle.lockedFor(email), const Duration(seconds: 120));
  });

  test('lockout is capped at 15 min', () async {
    // Keep attacking right after each lockout ends.
    for (var i = 0; i < 12; i++) {
      await fail(5);
      now = now.add(throttle.lockedFor(email)! + const Duration(seconds: 1));
    }
    await fail(5);
    expect(throttle.lockedFor(email), LoginThrottle.maxLockout);
  });

  test('failures older than 15 min are forgotten', () async {
    await fail(4);
    now = now.add(const Duration(minutes: 16));
    await fail(1);
    expect(throttle.lockedFor(email), isNull);
    await fail(3);
    expect(throttle.lockedFor(email), isNull);
    await fail(1);
    expect(throttle.lockedFor(email), const Duration(seconds: 30));
  });

  test('a long pause after a lockout starts over at 30 s', () async {
    await fail(5);
    now = now.add(const Duration(hours: 1));
    await fail(5);
    expect(throttle.lockedFor(email), const Duration(seconds: 30));
  });

  test('never stores the email itself', () async {
    await fail(5);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isNotEmpty);
    for (final k in prefs.getKeys()) {
      expect(k, isNot(contains('ana')), reason: k);
      expect(k, isNot(contains('example')), reason: k);
    }
  });

  test('reset clears failures and lockout', () async {
    await fail(5);
    await throttle.reset(email);
    expect(throttle.lockedFor(email), isNull);
    await fail(4);
    expect(throttle.lockedFor(email), isNull);
  });

  test('emails are tracked separately', () async {
    await fail(5);
    expect(throttle.lockedFor('otro@example.com'), isNull);
  });
}
