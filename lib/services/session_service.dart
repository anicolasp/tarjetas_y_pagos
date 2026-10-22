import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key-value store for secrets, so tests can use an in-memory one.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Keeps the logged-in user across app restarts, plus the last user that
/// logged in (offered for biometric login after logging out).
class SessionService {
  const SessionService(this._store);

  static const _sessionKey = 'session_user_id';
  static const _lastUserKey = 'last_user_id';

  final SecureStore _store;

  Future<int?> currentUserId() async =>
      int.tryParse(await _store.read(_sessionKey) ?? '');

  Future<int?> lastUserId() async =>
      int.tryParse(await _store.read(_lastUserKey) ?? '');

  Future<void> start(int userId) async {
    await _store.write(_sessionKey, '$userId');
    await _store.write(_lastUserKey, '$userId');
  }

  /// Ends the session but remembers [lastUserId].
  Future<void> end() => _store.delete(_sessionKey);
}
