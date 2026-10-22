import 'dart:convert';

import 'package:cryptography/dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Progressive lockout after repeated failed logins for the same email:
/// every [maxAttempts] failures locks the email for 30 s, then 60 s, 120 s…
/// (capped at [maxLockout]). A successful login resets it, and failures
/// older than [failureWindow] are forgotten so occasional typos over weeks
/// never add up to a lockout.
///
/// Emails are never stored: preference keys use their SHA-256.
class LoginThrottle {
  LoginThrottle(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const maxAttempts = 5;
  static const baseLockout = Duration(seconds: 30);
  static const maxLockout = Duration(minutes: 15);
  static const failureWindow = Duration(minutes: 15);

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  String _id(String email) => base64Url
      .encode(const DartSha256().hashSync(utf8.encode(email)).bytes)
      .replaceAll('=', '');

  String _failuresKey(String email) => 'login_throttle.failures.${_id(email)}';
  String _lastFailureKey(String email) => 'login_throttle.last.${_id(email)}';
  String _untilKey(String email) => 'login_throttle.until.${_id(email)}';

  /// Remaining lockout for [email], or null if it can try now.
  Duration? lockedFor(String email) {
    final until = _prefs.getInt(_untilKey(email));
    if (until == null) return null;
    final remaining = DateTime.fromMillisecondsSinceEpoch(until)
        .difference(_clock());
    return remaining > Duration.zero ? remaining : null;
  }

  Future<void> registerFailure(String email) async {
    final now = _clock();
    // Quiet for longer than the window, counted from the last failure or the
    // end of the last lockout (whichever is later): start over.
    final last = _prefs.getInt(_lastFailureKey(email)) ?? 0;
    final lockedUntil = _prefs.getInt(_untilKey(email)) ?? 0;
    final quietSince = DateTime.fromMillisecondsSinceEpoch(
      last > lockedUntil ? last : lockedUntil,
    );
    final stale = now.difference(quietSince) > failureWindow;
    final previous = stale ? 0 : _prefs.getInt(_failuresKey(email)) ?? 0;

    final failures = previous + 1;
    await _prefs.setInt(_failuresKey(email), failures);
    await _prefs.setInt(_lastFailureKey(email), now.millisecondsSinceEpoch);
    if (failures % maxAttempts != 0) return;

    final lockouts = failures ~/ maxAttempts;
    var lockout = baseLockout * (1 << (lockouts - 1).clamp(0, 30));
    if (lockout > maxLockout) lockout = maxLockout;
    await _prefs.setInt(
      _untilKey(email),
      now.add(lockout).millisecondsSinceEpoch,
    );
  }

  Future<void> reset(String email) async {
    await _prefs.remove(_failuresKey(email));
    await _prefs.remove(_lastFailureKey(email));
    await _prefs.remove(_untilKey(email));
  }
}
