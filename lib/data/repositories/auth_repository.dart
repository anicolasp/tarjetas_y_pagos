import 'package:sqflite/sqflite.dart';

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
  }) async {
    final error =
        validateName(firstName, field: 'nombre') ??
        validateName(lastName, field: 'apellido') ??
        validateEmail(email) ??
        validatePassword(password);
    if (error != null) throw ArgumentError(error);

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
      createdAt: _clock(),
    );
    try {
      final id = await _db.db.insert('users', user.toMap());
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
