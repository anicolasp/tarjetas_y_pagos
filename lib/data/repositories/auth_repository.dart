import 'package:flutter/material.dart' show StringCharacters, ThemeMode;
import 'package:sqflite/sqflite.dart';

import '../../core/accessibility.dart';
import '../../core/language.dart';
import '../../core/money.dart';
import '../../core/security_question.dart';
import '../../core/validators.dart';
import '../../services/login_throttle.dart';
import '../../services/password_hasher.dart';
import '../database.dart';
import '../models/app_user.dart';

class EmailTakenException implements Exception {
  const EmailTakenException();
}

/// Wrong email or password. Deliberately does not say which one.
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
}

class LockedOutException implements Exception {
  const LockedOutException(this.remaining);

  final Duration remaining;
}

/// The current password given to confirm a change is wrong.
class WrongPasswordException implements Exception {
  const WrongPasswordException();
}

/// No account uses that email (password recovery, #27).
class AccountNotFoundException implements Exception {
  const AccountNotFoundException();
}

/// The account was created before #27 and has no security question.
class NoSecurityQuestionException implements Exception {
  const NoSecurityQuestionException();
}

/// The answer to the security question is wrong.
class WrongAnswerException implements Exception {
  const WrongAnswerException();
}

/// The Google account's email already has an account without Google: it
/// is linked with that account's password ([AuthRepository.linkGoogle]).
class GoogleLinkNeededException implements Exception {
  const GoogleLinkNeededException();
}

/// That Google account is already linked to another user.
class GoogleAccountTakenException implements Exception {
  const GoogleAccountTakenException();
}

/// The account is already linked to a different Google account: linking
/// another would silently cut that one off.
class GoogleAlreadyLinkedException implements Exception {
  const GoogleAlreadyLinkedException();
}

/// The account was created with Google and has no password yet: it signs
/// in with Google (no password to check or to recover).
class GoogleOnlyAccountException implements Exception {
  const GoogleOnlyAccountException();
}

/// Days of notice before cuts, due dates and debts (#10).
const notifyDaysRange = (min: 0, max: 30);

/// Local accounts: registration and login against the `users` table.
/// Never logs emails or passwords.
class AuthRepository {
  AuthRepository(
    this._db,
    this._hasher,
    this._throttle, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final PasswordHasher _hasher;
  final LoginThrottle _throttle;
  final DateTime Function() _clock;

  /// Used to spend the same time hashing when the email does not exist.
  static const _dummySalt = 'AAAAAAAAAAAAAAAAAAAAAA==';

  /// Throws [ArgumentError] for invalid input and [EmailTakenException].
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    AppLanguage language = AppLanguage.es,
    SecurityQuestion? securityQuestion,
    String? securityAnswer,
  }) async {
    final error =
        validateName(firstName, field: NameField.first) ??
        validateName(lastName, field: NameField.last) ??
        validateEmail(email) ??
        validatePassword(password) ??
        (securityQuestion == null
            ? null
            : _validateQuestion(securityQuestion, securityAnswer));
    if (error != null) throw FieldErrorException(error);

    final normalized = normalizeEmail(email);
    if (await _findByEmail(normalized) != null) {
      throw const EmailTakenException();
    }

    final salt = _hasher.newSalt();
    final user = AppUser(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalized,
      passwordHash: await _hasher.hash(password, salt),
      salt: salt,
      language: language,
      securityQuestion: securityQuestion,
      createdAt: _clock(),
    );
    try {
      final id = await _db.db.insert('users', {
        ...user.toMap(),
        if (securityQuestion != null) ...await _answerColumns(securityAnswer!),
      });
      return user.copyWith(id: id);
    } on DatabaseException catch (e) {
      // Lost a race with another registration of the same email.
      if (e.isUniqueConstraintError()) throw const EmailTakenException();
      rethrow;
    }
  }

  /// Throws [LockedOutException] or [InvalidCredentialsException].
  Future<AppUser> login(String email, String password) async {
    final normalized = normalizeEmail(email);
    AppUser? user;
    await _throttled(normalized, const InvalidCredentialsException(), () async {
      user = await _findByEmail(normalized);
      if (user != null && !user!.hasPassword) {
        // Same work as a wrong password; not counted: no guess was made.
        await _hasher.hash(password, _dummySalt);
        throw const GoogleOnlyAccountException();
      }
      return _checkPassword(user, password);
    });
    if (_hasher.needsRehash(user!.passwordHash)) {
      return _rehash(user!, password);
    }
    return user!;
  }

  Future<AppUser?> getById(int id) async {
    final rows = await _db.db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.single);
  }

  // ------------------------------------------------------------- profile

  Future<AppUser> updateName(int userId, String firstName, String lastName) {
    final error =
        validateName(firstName, field: NameField.first) ??
        validateName(lastName, field: NameField.last);
    if (error != null) throw FieldErrorException(error);
    return _update(userId, {
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
    });
  }

  /// Needs the current password. Throws [WrongPasswordException],
  /// [LockedOutException], [EmailTakenException] or [ArgumentError].
  Future<AppUser> changeEmail(
    int userId, {
    required String currentPassword,
    required String newEmail,
  }) async {
    final error = validateEmail(newEmail);
    if (error != null) throw FieldErrorException(error);
    final user = await _verifiedUser(userId, currentPassword);
    final normalized = normalizeEmail(newEmail);
    if (normalized == user.email) return user;
    if (await _findByEmail(normalized) != null) {
      throw const EmailTakenException();
    }
    try {
      return await _update(userId, {'email': normalized});
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw const EmailTakenException();
      rethrow;
    }
  }

  /// Needs the current password; the new one gets a new salt. Throws
  /// [WrongPasswordException], [LockedOutException] or [ArgumentError].
  Future<AppUser> changePassword(
    int userId, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final error = validatePassword(newPassword);
    if (error != null) throw FieldErrorException(error);
    final user = await _verifiedUser(userId, currentPassword);
    if (newPassword == currentPassword) {
      throw FieldErrorException(FieldError.samePassword);
    }
    final salt = _hasher.newSalt();
    return _update(user.id!, {
      'salt': salt,
      'password_hash': await _hasher.hash(newPassword, salt),
    });
  }

  /// Preferences; only the given ones change.
  Future<AppUser> updatePreferences(
    int userId, {
    ThemeMode? themeMode,
    Currency? defaultCurrency,
    int? notifyDaysBefore,
    bool? biometricEnabled,
    AppLanguage? language,
    A11ySettings? a11y,
  }) {
    if (notifyDaysBefore != null &&
        (notifyDaysBefore < notifyDaysRange.min ||
            notifyDaysBefore > notifyDaysRange.max)) {
      // The UI stepper never goes out of range: a programming error.
      throw RangeError.range(
        notifyDaysBefore,
        notifyDaysRange.min,
        notifyDaysRange.max,
        'notifyDaysBefore',
      );
    }
    return _update(userId, {
      'theme_mode': ?themeMode?.name,
      'default_currency': ?defaultCurrency?.code,
      'notify_days_before': ?notifyDaysBefore,
      'language': ?language?.code,
      if (biometricEnabled != null)
        'biometric_enabled': biometricEnabled ? 1 : 0,
      if (a11y != null) ...{
        'text_size': a11y.textSize.name,
        'legible_font': a11y.legibleFont ? 1 : 0,
        'bold_text': a11y.boldText ? 1 : 0,
        'high_contrast': a11y.highContrast ? 1 : 0,
      },
    });
  }

  // ------------------------------------------------------- google (#37)

  /// The user linked to [sub], or a new one for [email] (no password;
  /// [created] tells the caller to start the setup wizard). Throws
  /// [GoogleLinkNeededException] when [email] already has an account
  /// without Google.
  Future<({AppUser user, bool created})> loginWithGoogle({
    required String sub,
    required String email,
    String? name,
    AppLanguage language = AppLanguage.es,
  }) async {
    final linked = await _findByGoogle(sub);
    if (linked != null) return (user: linked, created: false);
    final normalized = normalizeEmail(email);
    if (await _findByEmail(normalized) != null) {
      throw const GoogleLinkNeededException();
    }
    final (first, last) = _splitName(name, normalized);
    final user = AppUser(
      firstName: first,
      lastName: last,
      email: normalized,
      passwordHash: '',
      salt: '',
      language: language,
      googleSub: sub,
      createdAt: _clock(),
    );
    try {
      final id = await _db.db.insert('users', user.toMap());
      return (user: user.copyWith(id: id), created: true);
    } on DatabaseException catch (e) {
      if (!e.isUniqueConstraintError()) rethrow;
      // Lost a race: the same Google account or email was just added.
      final now = await _findByGoogle(sub);
      if (now != null) return (user: now, created: false);
      throw const GoogleLinkNeededException();
    }
  }

  /// Links [sub] to the account of [email] once its password is right (same
  /// throttle as the login). Throws [InvalidCredentialsException],
  /// [LockedOutException], [GoogleAccountTakenException] or
  /// [GoogleAlreadyLinkedException].
  Future<AppUser> linkGoogle({
    required String email,
    required String password,
    required String sub,
  }) async {
    final user = await login(email, password);
    if (user.googleSub == sub) return user;
    if (user.googleSub != null) throw const GoogleAlreadyLinkedException();
    if (await _findByGoogle(sub) != null) {
      throw const GoogleAccountTakenException();
    }
    try {
      return await _update(user.id!, {'google_sub': sub});
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw const GoogleAccountTakenException();
      }
      rethrow;
    }
  }

  /// A first password for an account created with Google (it already
  /// proved who it is). Throws [FieldErrorException].
  Future<AppUser> setPassword(int userId, String newPassword) async {
    final error = validatePassword(newPassword);
    if (error != null) throw FieldErrorException(error);
    final user = await getById(userId);
    if (user == null) throw StateError('User not found');
    // Changing an existing one needs it ([changePassword]).
    if (user.hasPassword) throw StateError('Already has a password');
    final salt = _hasher.newSalt();
    return _update(userId, {
      'salt': salt,
      'password_hash': await _hasher.hash(newPassword, salt),
    });
  }

  /// Unlinks Google; needs the password, so the account always keeps a way
  /// in. Throws [WrongPasswordException] or [LockedOutException].
  Future<AppUser> unlinkGoogle(
    int userId, {
    required String currentPassword,
  }) async {
    await _verifiedUser(userId, currentPassword);
    return _update(userId, {'google_sub': null});
  }

  Future<AppUser?> _findByGoogle(String sub) async {
    final rows = await _db.db.query(
      'users',
      where: 'google_sub = ?',
      whereArgs: [sub],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.single);
  }

  /// "María José Pérez" → ("María", "José Pérez"); without a name, the
  /// part of the email before "@". Google may give one word: the last name
  /// stays empty (the name form asks for it). Cut to what [validateName]
  /// accepts, never in the middle of a character.
  (String, String) _splitName(String? name, String email) {
    String cut(String s) {
      final out = StringBuffer();
      for (final c in s.characters) {
        if (out.length + c.length > nameMaxLength) break;
        out.write(c);
      }
      return out.toString();
    }

    final parts = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return (cut(email.split('@').first), '');
    return (cut(parts.first), cut(parts.skip(1).join(' ')));
  }

  // ------------------------------------------------------ recovery (#27)

  /// The question to show for [email]. Throws [AccountNotFoundException]
  /// or [NoSecurityQuestionException].
  Future<SecurityQuestion> securityQuestionFor(String email) async {
    final user = await _findByEmail(normalizeEmail(email));
    if (user == null) throw const AccountNotFoundException();
    if (!user.hasPassword) throw const GoogleOnlyAccountException();
    return user.securityQuestion ?? (throw const NoSecurityQuestionException());
  }

  /// A new password for whoever answers the security question. Wrong
  /// answers count against the same per-email throttle as the login; the
  /// right one resets it. Data and biometrics are untouched. Throws
  /// [AccountNotFoundException], [NoSecurityQuestionException],
  /// [LockedOutException], [WrongAnswerException] or [FieldErrorException].
  Future<AppUser> resetPasswordWithAnswer({
    required String email,
    required String answer,
    required String newPassword,
  }) async {
    final error = validatePassword(newPassword);
    if (error != null) throw FieldErrorException(error);
    final user = await _userWithAnswer(email, answer);
    if (await _hasher.verify(newPassword, user.salt, user.passwordHash)) {
      throw FieldErrorException(FieldError.samePassword);
    }
    final newSalt = _hasher.newSalt();
    return _update(user.id!, {
      'salt': newSalt,
      'password_hash': await _hasher.hash(newPassword, newSalt),
    });
  }

  /// Checks the answer before the new password is asked for (same
  /// throttle and exceptions as [resetPasswordWithAnswer]).
  Future<void> checkSecurityAnswer(String email, String answer) =>
      _userWithAnswer(email, answer);

  Future<AppUser> _userWithAnswer(String email, String answer) async {
    final normalized = normalizeEmail(email);
    late final Map<String, Object?> row;
    await _throttled(normalized, const WrongAnswerException(), () async {
      final rows = await _db.db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalized],
        limit: 1,
      );
      if (rows.isEmpty) throw const AccountNotFoundException();
      row = rows.single;
      final hash = row['security_answer_hash'] as String?;
      final salt = row['security_salt'] as String?;
      if (hash == null || salt == null) {
        throw const NoSecurityQuestionException();
      }
      return _hasher.verify(normalizeSecurityAnswer(answer), salt, hash);
    });
    return AppUser.fromMap(row);
  }

  /// Sets or changes the security question; needs the current password.
  /// Throws [WrongPasswordException], [LockedOutException] or
  /// [FieldErrorException].
  Future<AppUser> setSecurityQuestion(
    int userId, {
    required String currentPassword,
    required SecurityQuestion question,
    required String answer,
  }) async {
    final error = _validateQuestion(question, answer);
    if (error != null) throw FieldErrorException(error);
    await _verifiedUser(userId, currentPassword);
    return _update(userId, {
      'security_question': question.encode(),
      ...await _answerColumns(answer),
    });
  }

  FieldError? _validateQuestion(SecurityQuestion question, String? answer) =>
      (question is CustomQuestion
          ? validateCustomQuestion(question.text)
          : null) ??
      validateSecurityAnswer(answer);

  /// The answer, normalized and hashed with its own salt.
  Future<Map<String, Object?>> _answerColumns(String answer) async {
    final salt = _hasher.newSalt();
    return {
      'security_salt': salt,
      'security_answer_hash': await _hasher.hash(
        normalizeSecurityAnswer(answer),
        salt,
      ),
    };
  }

  /// The user, once [password] is confirmed. Wrong guesses count against
  /// the same per-email throttle as the login.
  Future<AppUser> _verifiedUser(int userId, String password) async {
    final user = await getById(userId);
    if (user == null) throw StateError('User not found');
    await _throttled(
      user.email,
      const WrongPasswordException(),
      () => _checkPassword(user, password),
    );
    return user;
  }

  /// [password] against [user]'s. No user, or one created with Google that
  /// has none, takes as long as a wrong password: the time never tells.
  Future<bool> _checkPassword(AppUser? user, String password) async {
    if (user == null || !user.hasPassword) {
      await _hasher.hash(password, _dummySalt);
      return false;
    }
    return _hasher.verify(password, user.salt, user.passwordHash);
  }

  /// One guess (password or answer) for [email], under the login's
  /// progressive lockout: locked → [LockedOutException]; [check] false →
  /// counts a failure and throws [wrong] (or the lockout it caused); true
  /// → the failures are forgotten.
  Future<void> _throttled(
    String email,
    Exception wrong,
    Future<bool> Function() check,
  ) async {
    final locked = _throttle.lockedFor(email);
    if (locked != null) throw LockedOutException(locked);
    if (!await check()) {
      await _throttle.registerFailure(email);
      final nowLocked = _throttle.lockedFor(email);
      if (nowLocked != null) throw LockedOutException(nowLocked);
      throw wrong;
    }
    await _throttle.reset(email);
  }

  Future<AppUser> _update(int userId, Map<String, Object?> values) async {
    if (values.isNotEmpty) {
      final count = await _db.db.update(
        'users',
        values,
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (count == 0) throw StateError('User not found');
    }
    final user = await getById(userId);
    if (user == null) throw StateError('User not found');
    return user;
  }

  Future<AppUser?> _findByEmail(String normalizedEmail) async {
    final rows = await _db.db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.single);
  }

  Future<AppUser> _rehash(AppUser user, String password) async {
    final salt = _hasher.newSalt();
    final updated = user.copyWith(
      salt: salt,
      passwordHash: await _hasher.hash(password, salt),
    );
    await _db.db.update(
      'users',
      {'salt': updated.salt, 'password_hash': updated.passwordHash},
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return updated;
  }
}
