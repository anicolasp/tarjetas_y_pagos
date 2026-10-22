import 'package:shared_preferences/shared_preferences.dart';

/// Progressive lockout after repeated failed logins for the same email:
/// every [maxAttempts] failures locks the email for 30 s, then 60 s, 120 s…
/// (capped at [maxLockout]). A successful login resets it.
class LoginThrottle {
  LoginThrottle(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const maxAttempts = 5;
  static const baseLockout = Duration(seconds: 30);
  static const maxLockout = Duration(minutes: 15);

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  String _failuresKey(String email) => 'login_throttle.failures.$email';
  String _untilKey(String email) => 'login_throttle.until.$email';

  /// Remaining lockout for [email], or null if it can try now.
  Duration? lockedFor(String email) {
    final until = _prefs.getInt(_untilKey(email));
    if (until == null) return null;
    final remaining = DateTime.fromMillisecondsSinceEpoch(until)
        .difference(_clock());
    return remaining > Duration.zero ? remaining : null;
  }

  Future<void> registerFailure(String email) async {
    final failures = (_prefs.getInt(_failuresKey(email)) ?? 0) + 1;
    await _prefs.setInt(_failuresKey(email), failures);
    if (failures % maxAttempts != 0) return;

    final lockouts = failures ~/ maxAttempts;
    var lockout = baseLockout * (1 << (lockouts - 1).clamp(0, 30));
    if (lockout > maxLockout) lockout = maxLockout;
    await _prefs.setInt(
      _untilKey(email),
      _clock().add(lockout).millisecondsSinceEpoch,
    );
  }

  Future<void> reset(String email) async {
    await _prefs.remove(_failuresKey(email));
    await _prefs.remove(_untilKey(email));
  }
}
