import 'package:flutter/material.dart' show ThemeMode;
import 'package:sqflite/sqflite.dart';

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
    final locked = _throttle.lockedFor(normalized);
    if (locked != null) throw LockedOutException(locked);

    final user = await _findByEmail(normalized);
    final valid = user == null
        ? await _hasher.hash(password, _dummySalt).then((_) => false)
        : await _hasher.verify(password, user.salt, user.passwordHash);

    if (!valid) {
      await _throttle.registerFailure(normalized);
      final nowLocked = _throttle.lockedFor(normalized);
      if (nowLocked != null) throw LockedOutException(nowLocked);
      throw const InvalidCredentialsException();
    }

    await _throttle.reset(normalized);
    if (_hasher.needsRehash(user!.passwordHash)) {
      return _rehash(user, password);
    }
    return user;
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
    });
  }

  // ------------------------------------------------------ recovery (#27)

  /// The question to show for [email]. Throws [AccountNotFoundException]
  /// or [NoSecurityQuestionException].
  Future<SecurityQuestion> securityQuestionFor(String email) async {
    final user = await _findByEmail(normalizeEmail(email));
    if (user == null) throw const AccountNotFoundException();
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
    final locked = _throttle.lockedFor(normalized);
    if (locked != null) throw LockedOutException(locked);

    final rows = await _db.db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) throw const AccountNotFoundException();
    final row = rows.single;
    final hash = row['security_answer_hash'] as String?;
    final salt = row['security_salt'] as String?;
    if (hash == null || salt == null) {
      throw const NoSecurityQuestionException();
    }
    if (!await _hasher.verify(normalizeSecurityAnswer(answer), salt, hash)) {
      await _throttle.registerFailure(normalized);
      final nowLocked = _throttle.lockedFor(normalized);
      if (nowLocked != null) throw LockedOutException(nowLocked);
      throw const WrongAnswerException();
    }
    await _throttle.reset(normalized);
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
    if (user == null) throw StateError('Usuario no encontrado');
    final locked = _throttle.lockedFor(user.email);
    if (locked != null) throw LockedOutException(locked);
    if (!await _hasher.verify(password, user.salt, user.passwordHash)) {
      await _throttle.registerFailure(user.email);
      final nowLocked = _throttle.lockedFor(user.email);
      if (nowLocked != null) throw LockedOutException(nowLocked);
      throw const WrongPasswordException();
    }
    await _throttle.reset(user.email);
    return user;
  }

  Future<AppUser> _update(int userId, Map<String, Object?> values) async {
    if (values.isNotEmpty) {
      final count = await _db.db.update(
        'users',
        values,
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (count == 0) throw StateError('Usuario no encontrado');
    }
    final user = await getById(userId);
    if (user == null) throw StateError('Usuario no encontrado');
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
